#!/bin/sh

set -eu

: "${SCRIPT_DIR:=$(CDPATH='' cd "$(dirname "$0")" && pwd)}"
SCENARIO_DIR=$(CDPATH='' cd "${SCRIPT_DIR}/.." && pwd)

: "${RESTAURANT_DATA_FILE:=${SCENARIO_DIR}/data/restaurant_reviews.csv}"
: "${CONTAINER_NAME:=restaurant-reviews}"
: "${BLOB_NAME:=restaurant_reviews.csv}"
: "${KNOWLEDGE_SOURCE_NAME:=restaurant-reviews-ks}"
: "${KNOWLEDGE_BASE_NAME:=restaurant-reviews-kb}"
: "${PROJECT_CONNECTION_NAME:=restaurant-reviews-kb-mcp}"
: "${AGENT_NAME:=restaurant-qa-agent}"
: "${AGENT_MODEL:=gpt-5.4-mini}"
: "${EMBEDDING_DEPLOYMENT:=text-embedding-3-large}"
: "${EMBEDDING_MODEL:=text-embedding-3-large}"
: "${SEARCH_API_VERSION:=2026-08-01-preview}"
: "${PROJECT_CONNECTION_API_VERSION:=2025-10-01-preview}"
: "${AGENT_API_VERSION:=v1}"
: "${STORAGE_API_VERSION:=2026-04-06}"
: "${VERBOSE_OUTPUT:=false}"
: "${KEEP_CONVERSATION:=false}"

HTTP_BODY_FILE=""
HTTP_STATUS=""

log() {
  printf '%s\n' "$*"
}

verbose_log() {
  if [ "$VERBOSE_OUTPUT" = "true" ]; then
    log "[verbose] $*"
  fi
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

parse_common_options() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --verbose)
        VERBOSE_OUTPUT=true
        ;;
      --)
        shift
        [ "$#" -eq 0 ] || die "Unexpected argument: $1"
        break
        ;;
      *)
        die "Unexpected argument: $1"
        ;;
    esac
    shift
  done

  validate_boolean VERBOSE_OUTPUT "$VERBOSE_OUTPUT"
}

parse_question_options() {
  COMMON_DEFAULT_QUESTION=$1
  shift
  COMMON_QUESTION_ARGUMENT=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --verbose)
        VERBOSE_OUTPUT=true
        ;;
      --)
        shift
        if [ "$#" -gt 0 ]; then
          COMMON_QUESTION_ARGUMENT=$*
        fi
        break
        ;;
      --*)
        die "Unexpected option: $1"
        ;;
      *)
        if [ -n "$COMMON_QUESTION_ARGUMENT" ]; then
          COMMON_QUESTION_ARGUMENT="${COMMON_QUESTION_ARGUMENT} $1"
        else
          COMMON_QUESTION_ARGUMENT=$1
        fi
        ;;
    esac
    shift
  done

  validate_boolean VERBOSE_OUTPUT "$VERBOSE_OUTPUT"
  if [ -n "$COMMON_QUESTION_ARGUMENT" ]; then
    QUESTION=$COMMON_QUESTION_ARGUMENT
  else
    : "${QUESTION:=$COMMON_DEFAULT_QUESTION}"
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_common_commands() {
  require_command az
  require_command curl
  require_command date
  require_command jq
  require_command terraform
}

terraform_output_value() {
  printf '%s' "$TERRAFORM_OUTPUTS" | jq -r --arg output_name "$1" '.[$output_name].value // empty'
}

load_terraform_outputs() {
  verbose_log "Loading Terraform outputs from ${SCENARIO_DIR}."
  TERRAFORM_OUTPUTS=$(terraform -chdir="${SCENARIO_DIR}" output -json)

  if [ -z "${RESOURCE_GROUP_NAME:-}" ]; then
    RESOURCE_GROUP_NAME=$(terraform_output_value resource_group_name)
  fi
  if [ -z "${FOUNDRY_ACCOUNT_NAME:-}" ]; then
    FOUNDRY_ACCOUNT_NAME=$(terraform_output_value microsoft_foundry_account_name)
  fi
  if [ -z "${FOUNDRY_OPENAI_ENDPOINT:-}" ]; then
    FOUNDRY_OPENAI_ENDPOINT=$(terraform_output_value microsoft_foundry_openai_endpoint)
  fi
  if [ -z "${PROJECT_ID:-}" ]; then
    PROJECT_ID=$(terraform_output_value microsoft_foundry_project_id)
  fi
  if [ -z "${PROJECT_NAME:-}" ]; then
    PROJECT_NAME=$(terraform_output_value microsoft_foundry_project_name)
  fi
  if [ -z "${PROJECT_ENDPOINT:-}" ]; then
    PROJECT_ENDPOINT=$(terraform_output_value microsoft_foundry_project_endpoint)
  fi
  if [ -z "${SEARCH_ID:-}" ]; then
    SEARCH_ID=$(terraform_output_value azure_ai_search_id)
  fi
  if [ -z "${SEARCH_NAME:-}" ]; then
    SEARCH_NAME=$(terraform_output_value azure_ai_search_name)
  fi
  if [ -z "${SEARCH_ENDPOINT:-}" ]; then
    SEARCH_ENDPOINT=$(terraform_output_value azure_ai_search_endpoint)
  fi
  if [ -z "${STORAGE_ACCOUNT_ID:-}" ]; then
    STORAGE_ACCOUNT_ID=$(terraform_output_value blob_storage_account_id)
  fi
  if [ -z "${STORAGE_ACCOUNT_NAME:-}" ]; then
    STORAGE_ACCOUNT_NAME=$(terraform_output_value blob_storage_account_name)
  fi
  if [ -z "${BLOB_ENDPOINT:-}" ]; then
    BLOB_ENDPOINT=$(terraform_output_value blob_storage_endpoint)
  fi
  if [ -z "${OPERATOR_PRINCIPAL_ID:-}" ]; then
    OPERATOR_PRINCIPAL_ID=$(terraform_output_value operator_principal_id)
  fi

  FOUNDRY_DEPLOYMENT_IDS_JSON=$(printf '%s' "$TERRAFORM_OUTPUTS" | jq -c '.microsoft_foundry_deployment_ids.value // {}')

  FOUNDRY_OPENAI_ENDPOINT=${FOUNDRY_OPENAI_ENDPOINT%/}
  PROJECT_ENDPOINT=${PROJECT_ENDPOINT%/}
  SEARCH_ENDPOINT=${SEARCH_ENDPOINT%/}
  BLOB_ENDPOINT=${BLOB_ENDPOINT%/}

  if [ -z "${AZURE_SUBSCRIPTION_ID:-}" ] && [ -n "$PROJECT_ID" ]; then
    AZURE_SUBSCRIPTION_ID=$(printf '%s' "$PROJECT_ID" | cut -d/ -f3)
  fi
  verbose_log "Loaded Terraform outputs for project ${PROJECT_NAME:-<unset>}."
}

require_value() {
  VALUE_LABEL=$1
  VALUE_CONTENT=$2
  [ -n "$VALUE_CONTENT" ] || die "Terraform output is empty: ${VALUE_LABEL}. Apply with enable_standard_setup=true first."
}

require_standard_agent_outputs() {
  require_value microsoft_foundry_openai_endpoint "$FOUNDRY_OPENAI_ENDPOINT"
  require_value microsoft_foundry_project_id "$PROJECT_ID"
  require_value microsoft_foundry_project_endpoint "$PROJECT_ENDPOINT"
  require_value azure_ai_search_id "$SEARCH_ID"
  require_value azure_ai_search_endpoint "$SEARCH_ENDPOINT"
  require_value blob_storage_account_id "$STORAGE_ACCOUNT_ID"
  require_value blob_storage_endpoint "$BLOB_ENDPOINT"
  require_value operator_principal_id "$OPERATOR_PRINCIPAL_ID"
  require_value subscription_id "$AZURE_SUBSCRIPTION_ID"
}

require_model_deployment() {
  printf '%s' "$FOUNDRY_DEPLOYMENT_IDS_JSON" | jq -e --arg deployment_name "$1" 'has($deployment_name)' >/dev/null \
    || die "Model deployment is missing from Terraform outputs: $1"
}

get_access_token() {
  verbose_log "Requesting an Azure access token for scope $1." >&2
  az account get-access-token \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --scope "$1" \
    --query accessToken \
    --output tsv
}

storage_request_date() {
  LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S GMT'
}

cleanup_http_body() {
  if [ -n "$HTTP_BODY_FILE" ] && [ -f "$HTTP_BODY_FILE" ]; then
    rm -f "$HTTP_BODY_FILE"
  fi
  HTTP_BODY_FILE=""
}

trap 'cleanup_http_body' 0
trap 'cleanup_http_body; exit 1' HUP INT TERM

http_request() {
  HTTP_REQUEST_METHOD=GET
  HTTP_REQUEST_URL=""
  HTTP_REQUEST_METHOD_NEXT=false
  for HTTP_REQUEST_ARGUMENT do
    if [ "$HTTP_REQUEST_METHOD_NEXT" = "true" ]; then
      HTTP_REQUEST_METHOD=$HTTP_REQUEST_ARGUMENT
      HTTP_REQUEST_METHOD_NEXT=false
      continue
    fi
    case "$HTTP_REQUEST_ARGUMENT" in
      --request)
        HTTP_REQUEST_METHOD_NEXT=true
        ;;
      http://*|https://*)
        HTTP_REQUEST_URL=$HTTP_REQUEST_ARGUMENT
        ;;
    esac
  done
  [ "$HTTP_REQUEST_METHOD_NEXT" = "false" ] || die "HTTP request method is missing."
  [ -n "$HTTP_REQUEST_URL" ] || die "HTTP request URL is missing."
  verbose_log "HTTP request: ${HTTP_REQUEST_METHOD} ${HTTP_REQUEST_URL}"

  cleanup_http_body
  HTTP_BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/foundry-iq-http.XXXXXX")

  if HTTP_STATUS=$(curl --silent --show-error --output "$HTTP_BODY_FILE" --write-out '%{http_code}' "$@"); then
    verbose_log "HTTP response: ${HTTP_STATUS} ${HTTP_REQUEST_METHOD} ${HTTP_REQUEST_URL}"
    return 0
  fi

  verbose_log "HTTP request failed: ${HTTP_REQUEST_METHOD} ${HTTP_REQUEST_URL}"
  if [ -s "$HTTP_BODY_FILE" ]; then
    cat "$HTTP_BODY_FILE" >&2
  fi
  die "HTTP request failed before a response was received."
}

print_http_body() {
  if [ ! -s "$HTTP_BODY_FILE" ]; then
    return 0
  fi

  if jq . "$HTTP_BODY_FILE" 2>/dev/null; then
    return 0
  fi

  cat "$HTTP_BODY_FILE"
}

expect_http_status() {
  EXPECTED_HTTP_STATUSES=" $* "
  case "$EXPECTED_HTTP_STATUSES" in
    *" $HTTP_STATUS "*) return 0 ;;
  esac

  print_http_body >&2
  die "Unexpected HTTP status ${HTTP_STATUS}; expected one of:$*"
}

url_encode() {
  jq -nr --arg value "$1" '$value | @uri'
}

validate_resource_name() {
  RESOURCE_LABEL=$1
  RESOURCE_VALUE=$2
  case "$RESOURCE_VALUE" in
    ''|*[!a-z0-9-]*) die "${RESOURCE_LABEL} must contain only lowercase letters, digits, and hyphens: ${RESOURCE_VALUE}" ;;
  esac
}

validate_blob_name() {
  case "$1" in
    ''|*[!A-Za-z0-9._-]*) die "BLOB_NAME contains unsupported characters: $1" ;;
  esac
}

validate_positive_integer() {
  INTEGER_LABEL=$1
  INTEGER_VALUE=$2
  case "$INTEGER_VALUE" in
    ''|*[!0-9]*) die "${INTEGER_LABEL} must be a positive integer: ${INTEGER_VALUE}" ;;
  esac
  [ "$INTEGER_VALUE" -gt 0 ] || die "${INTEGER_LABEL} must be greater than zero."
}

validate_boolean() {
  BOOLEAN_LABEL=$1
  BOOLEAN_VALUE=$2
  case "$BOOLEAN_VALUE" in
    true|false) ;;
    *) die "${BOOLEAN_LABEL} must be true or false: ${BOOLEAN_VALUE}" ;;
  esac
}