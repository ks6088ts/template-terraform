#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
: "${PLAYGROUND_TENANT:=cosmos-playground-demo}"
: "${PLAYGROUND_TAG:=cosmos-playground-v1}"
: "${COSMOS_API_VERSION:=2018-12-31}"
: "${POLL_ATTEMPTS:=12}"
: "${POLL_INTERVAL:=5}"

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }
log() { printf '%s\n' "$*"; }
uri() { jq -nr --arg s "$1" '$s | @uri'; }

require_tools() {
  for tool in curl jq az; do
    command -v "$tool" >/dev/null 2>&1 || die "Missing required command: $tool"
  done
}

load_outputs() {
  if [ -n "${TF_OUTPUT_FILE:-}" ]; then
    [ -r "$TF_OUTPUT_FILE" ] || die "Cannot read TF_OUTPUT_FILE"
    outputs=$(jq -c . "$TF_OUTPUT_FILE")
  else
    outputs=${TF_OUTPUT_JSON:-'{}'}
  fi
  printf '%s' "$outputs" | jq -e 'type == "object"' >/dev/null || die "Invalid Terraform output JSON"
  for key in cosmos_endpoint cosmos_database_name cosmos_container_name foundry_endpoint embedding_deployment_name chat_deployment_name vector_dimensions; do
    value=$(printf '%s' "$outputs" | jq -r --arg k "$key" '.[$k].value // empty')
    case "$key" in
      cosmos_endpoint) COSMOS_ENDPOINT=${COSMOS_ENDPOINT:-$value} ;;
      cosmos_database_name) COSMOS_DATABASE_NAME=${COSMOS_DATABASE_NAME:-$value} ;;
      cosmos_container_name) COSMOS_CONTAINER_NAME=${COSMOS_CONTAINER_NAME:-$value} ;;
      foundry_endpoint) FOUNDRY_ENDPOINT=${FOUNDRY_ENDPOINT:-$value} ;;
      embedding_deployment_name) EMBEDDING_DEPLOYMENT_NAME=${EMBEDDING_DEPLOYMENT_NAME:-$value} ;;
      chat_deployment_name) CHAT_DEPLOYMENT_NAME=${CHAT_DEPLOYMENT_NAME:-$value} ;;
      vector_dimensions) VECTOR_DIMENSIONS=${VECTOR_DIMENSIONS:-$value} ;;
    esac
  done
  for key in COSMOS_ENDPOINT COSMOS_DATABASE_NAME COSMOS_CONTAINER_NAME FOUNDRY_ENDPOINT EMBEDDING_DEPLOYMENT_NAME CHAT_DEPLOYMENT_NAME VECTOR_DIMENSIONS; do
    eval 'value=${'"$key"'-}'
    [ -n "$value" ] || die "Missing $key: supply TF_OUTPUT_FILE, TF_OUTPUT_JSON, or output environment variables"
  done
  case "$VECTOR_DIMENSIONS" in ''|0*|*[!0-9]*) die "vector_dimensions must be an integer from 1 to 505" ;; esac
  [ "$VECTOR_DIMENSIONS" -ge 1 ] && [ "$VECTOR_DIMENSIONS" -le 505 ] \
    || die "vector_dimensions must be an integer from 1 to 505"
  case "$COSMOS_ENDPOINT" in https://*) ;; *) die "cosmos_endpoint must be HTTPS" ;; esac
  case "$FOUNDRY_ENDPOINT" in https://*) ;; *) die "foundry_endpoint must be HTTPS" ;; esac
  COSMOS_ENDPOINT=${COSMOS_ENDPOINT%/}
  FOUNDRY_ENDPOINT=${FOUNDRY_ENDPOINT%/}
  case "$POLL_ATTEMPTS:$POLL_INTERVAL" in *[!0-9:]*|:*|*:) die "Polling settings must be nonnegative integers" ;; esac
  [ "$POLL_ATTEMPTS" -gt 0 ] || die "POLL_ATTEMPTS must be positive"
  DB_PATH="dbs/$(uri "$COSMOS_DATABASE_NAME")"
  COLL_PATH="$DB_PATH/colls/$(uri "$COSMOS_CONTAINER_NAME")"
  DOCS_PATH="$COLL_PATH/docs"
  PARTITION_KEY=$(jq -nc --arg key "$PLAYGROUND_TENANT" '[$key]')
}

get_tokens() {
  COSMOS_TOKEN=$(az account get-access-token --resource https://cosmos.azure.com/ --query accessToken -o tsv) || die "Cannot acquire Cosmos AAD token"
  [ -n "$COSMOS_TOKEN" ] || die "Empty Cosmos AAD token"
  COSMOS_AUTH=$(uri "type=aad&ver=1.0&sig=$COSMOS_TOKEN")
}

get_foundry_token() {
  FOUNDRY_TOKEN=$(az account get-access-token --resource https://cognitiveservices.azure.com/ --query accessToken -o tsv) || die "Cannot acquire Foundry AAD token"
  [ -n "$FOUNDRY_TOKEN" ] || die "Empty Foundry AAD token"
  FOUNDRY_AUTH=$(printf '%s %s' Bearer "$FOUNDRY_TOKEN")
}

request() {
  # No trace or curl -v: credentials are sent in headers and must never be logged.
  response=$(curl --silent --show-error --max-time 45 --include --write-out '
%{http_code}' "$@") || die "Network request failed"
  newline='
'
  HTTP_STATUS=${response##*"$newline"}
  raw=${response%"$newline$HTTP_STATUS"}
  cr=$(printf '\r')
  header_end="$cr
$cr
"
  case "$raw" in *"$header_end"*) ;; *) die "HTTP response has no headers" ;; esac
  HTTP_HEADERS=${raw%%"$header_end"*}
  HTTP_BODY=${raw#*"$header_end"}
  # HTTP/1.1 may include an interim 100 Continue header block.
  while :; do
    case "$HTTP_BODY" in
      HTTP/*"$header_end"*)
        HTTP_HEADERS=${HTTP_BODY%%"$header_end"*}
        HTTP_BODY=${HTTP_BODY#*"$header_end"}
        ;;
      *) break ;;
    esac
  done
  HTTP_ETAG=$(header_value etag)
  HTTP_CONTINUATION=$(header_value x-ms-continuation)
  new_session_token=$(header_value x-ms-session-token)
  if [ -n "$new_session_token" ]; then
    COSMOS_SESSION_TOKEN=$new_session_token
  fi
  case "$HTTP_STATUS" in
    2??|304|404|409|412) ;;
    *) die "HTTP $HTTP_STATUS: $(http_error_detail)" ;;
  esac
}

http_error_detail() {
  printf '%s' "$HTTP_BODY" | jq -r '
    [(.code // .error.code // empty), (.message // .error.message // empty)]
    | map(select(type == "string" and length > 0) | split("\n")[0])
    | if length > 0 then join(": ") else "request failed" end
  ' 2>/dev/null || printf 'request failed'
}

header_value() {
  printf '%s' "$HTTP_HEADERS" | jq -Rrs --arg key "$1" \
    'split("\r\n") | map(select(ascii_downcase | startswith($key + ":"))) | last // "" | sub("^[^:]*:[ \t]*"; "")'
}

cosmos_request() {
  method=$1 resource=$2 type=$3 path=$4
  shift 4
  if [ "$type" = docs ]; then
    set -- --header "x-ms-documentdb-partitionkey: $PARTITION_KEY" "$@"
  fi
  if [ -n "${COSMOS_SESSION_TOKEN:-}" ]; then
    set -- --header "x-ms-session-token: $COSMOS_SESSION_TOKEN" "$@"
  fi
  request --request "$method" \
    --header "authorization: $COSMOS_AUTH" \
    --header "x-ms-date: $(jq -nr 'now | gmtime | strftime("%a, %d %b %Y %H:%M:%S GMT")')" \
    --header "x-ms-version: $COSMOS_API_VERSION" \
    --header "Accept: application/json" \
    --header "x-ms-max-item-count: 100" \
    "$@" "$COSMOS_ENDPOINT/$path"
}

foundry_request() {
  method=$1 path=$2
  shift 2
  request --request "$method" \
    --header "Authorization: $FOUNDRY_AUTH" \
    --header "Content-Type: application/json" \
    "$@" "$FOUNDRY_ENDPOINT/$path"
}

expect_status() {
  expected=" $* "
  case "$expected" in *" $HTTP_STATUS "*) return 0 ;; esac
  die "Unexpected HTTP $HTTP_STATUS (expected $*): $(http_error_detail)"
}

document_path() { printf '%s/%s' "$DOCS_PATH" "$(uri "$1")"; }

read_document() {
  cosmos_request GET docs docs "$(document_path "$1")"
  expect_status 200 404
}

put_document() {
  doc=$1
  id=$(printf '%s' "$doc" | jq -er '.id')
  printf '%s' "$doc" | jq -e --arg tag "$PLAYGROUND_TAG" --arg tenant "$PLAYGROUND_TENANT" \
    '.playgroundTag == $tag and .tenantId == $tenant' >/dev/null || die "Refusing to write an untagged document"
  read_document "$id"
  if [ "$HTTP_STATUS" = 404 ]; then
    cosmos_request POST docs docs "$DOCS_PATH" \
      --header "Content-Type: application/json" --data "$doc"
    expect_status 201
  else
    printf '%s' "$HTTP_BODY" | jq -e --arg tag "$PLAYGROUND_TAG" --arg tenant "$PLAYGROUND_TENANT" \
      '.playgroundTag == $tag and .tenantId == $tenant' >/dev/null || die "Refusing to replace a document not owned by this playground"
    etag=${HTTP_ETAG:-$(printf '%s' "$HTTP_BODY" | jq -er '._etag')}
    cosmos_request PUT docs docs "$(document_path "$id")" \
      --header "Content-Type: application/json" --header "If-Match: $etag" --data "$doc"
    expect_status 200
  fi
}

delete_document() {
  id=$1
  read_document "$id"
  [ "$HTTP_STATUS" = 404 ] && return 0
  printf '%s' "$HTTP_BODY" | jq -e --arg tag "$PLAYGROUND_TAG" --arg tenant "$PLAYGROUND_TENANT" \
    '.playgroundTag == $tag and .tenantId == $tenant' >/dev/null || die "Refusing to delete a document not owned by this playground"
  etag=${HTTP_ETAG:-$(printf '%s' "$HTTP_BODY" | jq -er '._etag')}
  cosmos_request DELETE docs docs "$(document_path "$id")" --header "If-Match: $etag"
  expect_status 204 404
}

query_documents() {
  payload=$1
  if [ -n "${2:-}" ]; then
    cosmos_request POST docs docs "$DOCS_PATH" \
      --header "Content-Type: application/query+json" \
      --header "x-ms-documentdb-isquery: True" \
      --header "x-ms-documentdb-query-enablecrosspartition: True" \
      --header "x-ms-continuation: $2" \
      --data "$payload"
  else
    cosmos_request POST docs docs "$DOCS_PATH" \
      --header "Content-Type: application/query+json" \
      --header "x-ms-documentdb-isquery: True" \
      --header "x-ms-documentdb-query-enablecrosspartition: True" \
      --data "$payload"
  fi
  expect_status 200
}

wait_query_documents() {
  attempts=0
  while [ "$attempts" -lt "$POLL_ATTEMPTS" ]; do
    query_documents "$1"
    if printf '%s' "$HTTP_BODY" | jq -e '.Documents | length > 0' >/dev/null; then
      return 0
    fi
    attempts=$((attempts + 1))
    [ "$attempts" -lt "$POLL_ATTEMPTS" ] && sleep "$POLL_INTERVAL"
  done
  die "No indexed documents returned within polling limit"
}

tagged_query() {
  query=$1
  shift
  jq -nc --arg query "$query" --arg tenant "$PLAYGROUND_TENANT" --arg tag "$PLAYGROUND_TAG" \
    --argjson additional "${1:-[]}" \
    '{query:$query,parameters: ([{name:"@tenant",value:$tenant},{name:"@tag",value:$tag}] + $additional)}'
}

embed() {
  get_foundry_token
  payload=$(jq -nc --arg text "$1" --arg model "$EMBEDDING_DEPLOYMENT_NAME" \
    --argjson dimensions "$VECTOR_DIMENSIONS" '{model:$model,input:$text,dimensions:$dimensions}')
  foundry_request POST "openai/v1/embeddings" --data "$payload"
  expect_status 200
  EMBEDDING=$(printf '%s' "$HTTP_BODY" | jq -ec --argjson dimensions "$VECTOR_DIMENSIONS" \
    '.data[0].embedding | select(type == "array" and length == $dimensions)') || die "Unexpected embedding dimensions"
}

seed_documents() {
  for index in 1 2 3; do
    case "$index" in
      1) text="Azure Cosmos DB stores JSON documents with partition keys and low latency." ;;
      2) text="Vector search finds semantically related content using embeddings." ;;
      3) text="Change feed tracks inserts and updates; time to live expires documents." ;;
    esac
    embed "$text"
    doc=$(jq -nc --arg id "cosmos-playground-knowledge-$index" --arg tenant "$PLAYGROUND_TENANT" \
      --arg tag "$PLAYGROUND_TAG" --arg content "$text" --argjson embedding "$EMBEDDING" \
      '{id:$id,tenantId:$tenant,playgroundTag:$tag,content:$content,embedding:$embedding}')
    put_document "$doc"
  done
}
