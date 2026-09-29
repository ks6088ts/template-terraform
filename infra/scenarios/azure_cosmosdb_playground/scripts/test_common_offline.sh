#!/bin/sh
# Offline contract checks for _common.sh; no Azure account or network required.
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
equal() { [ "$1" = "$2" ] || fail "$3 (expected $1, got $2)"; }

az() { printf '%s\n' 'offline-token'; }
curl() {
  if [ "${mock_fail:-false}" = true ]; then
    return 28
  fi
  if [ -n "${mock_expected_header:-}" ]; then
    found=false
    for argument do
      [ "$argument" = "$mock_expected_header" ] && found=true
    done
    [ "$found" = true ] || return 1
  fi
  if [ -n "${mock_rejected_header:-}" ]; then
    for argument do
      [ "$argument" = "$mock_rejected_header" ] && return 1
    done
  fi
  printf '%s\r\n\r\n%s\n%s' "$mock_headers" "$mock_body" "$mock_status"
}

TF_OUTPUT_JSON=$(jq -nc '{
  cosmos_endpoint:{value:"https://example.documents.azure.com/"},
  cosmos_database_name:{value:"playground"},
  cosmos_container_name:{value:"documents"},
  foundry_endpoint:{value:"https://example.openai.azure.com/"},
  embedding_deployment_name:{value:"embedding"},
  chat_deployment_name:{value:"chat"},
  vector_dimensions:{value:505}
}')
load_outputs
equal 505 "$VECTOR_DIMENSIONS" "output dimensions"
equal 'dbs/playground/colls/documents/docs' "$DOCS_PATH" "output paths"
if (VECTOR_DIMENSIONS=0; load_outputs) >/dev/null 2>&1; then
  fail "zero dimensions accepted"
fi
if (VECTOR_DIMENSIONS=506; load_outputs) >/dev/null 2>&1; then
  fail "out-of-range dimensions accepted"
fi
get_tokens
get_foundry_token
equal 'offline-token' "$COSMOS_TOKEN" "Cosmos token acquisition"
scheme=$(printf 'B%s' earer)
equal "$scheme offline-token" "$FOUNDRY_AUTH" "Foundry token acquisition"

mock_headers=$(printf 'HTTP/1.1 200 OK\r\nETag: "cursor-1"\r\nx-ms-session-token: 0:session\r\nx-ms-continuation: page-2')
mock_body='{"Documents":[]}'
mock_status=200
request 'https://example.invalid/'
expect_status 200
equal "$mock_body" "$HTTP_BODY" "JSON response body"
equal '"cursor-1"' "$HTTP_ETAG" "ETag response header"
equal '0:session' "$COSMOS_SESSION_TOKEN" "session response header"
equal 'page-2' "$HTTP_CONTINUATION" "continuation response header"

partition_header="x-ms-documentdb-partitionkey: $PARTITION_KEY"
mock_rejected_header=$partition_header
cosmos_request GET colls colls "$COLL_PATH"
equal 200 "$HTTP_STATUS" "container request without partition key"
mock_rejected_header=
mock_expected_header=$partition_header
cosmos_request GET docs docs "$DOCS_PATH"
equal 200 "$HTTP_STATUS" "document request with partition key"

mock_expected_header='x-ms-session-token: 0:session'
cosmos_request GET docs docs "$DOCS_PATH"
expect_status 200
mock_expected_header='Content-Type: application/query+json'
mock_rejected_header='Content-Type: application/json'
query_documents '{"query":"SELECT * FROM c","parameters":[]}'
equal 200 "$HTTP_STATUS" "query content type"
mock_rejected_header=
mock_expected_header='x-ms-continuation: page-2'
query_documents '{"query":"SELECT * FROM c","parameters":[]}' "$HTTP_CONTINUATION"
equal 200 "$HTTP_STATUS" "query continuation request"
mock_expected_header=

mock_headers='HTTP/1.1 304 Not Modified'
mock_body=
mock_status=304
request 'https://example.invalid/'
expect_status 200 304
equal '' "$HTTP_BODY" "304 empty body"
equal '' "$HTTP_CONTINUATION" "304 resets continuation header"
equal '0:session' "$COSMOS_SESSION_TOKEN" "304 retains prior session token"

mock_headers='HTTP/1.1 404 Not Found'
mock_body='{"code":"NotFound"}'
mock_status=404
request 'https://example.invalid/'
expect_status 200 404
equal 404 "$HTTP_STATUS" "404 response"

mock_headers='HTTP/1.1 500 Internal Server Error'
mock_body='{"code":"InternalServerError"}'
mock_status=500
if (request 'https://example.invalid/') >/dev/null 2>&1; then
  fail "server error accepted"
fi
mock_fail=true
if (request 'https://example.invalid/') >/dev/null 2>&1; then
  fail "curl timeout accepted"
fi
printf '%s\n' 'Offline _common.sh checks passed.'
