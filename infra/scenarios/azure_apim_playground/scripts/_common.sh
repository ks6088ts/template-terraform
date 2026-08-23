#!/bin/sh

# shellcheck disable=SC2034

set -eu

: "${SCRIPT_DIR:=$(CDPATH='' cd "$(dirname "$0")" && pwd)}"
SCENARIO_DIR=$(CDPATH='' cd "${SCRIPT_DIR}/.." && pwd)

: "${CONTENT_SAFETY_API_VERSION:=2024-09-01}"
: "${CONTENT_SAFETY_BLOCKED_TEXT:=apim-playground-blocked-term}"
: "${CONTENT_SAFETY_PROPAGATION_SECONDS:=5}"
: "${LOG_QUERY_ATTEMPTS:=12}"
: "${LOG_QUERY_INTERVAL_SECONDS:=10}"

HTTP_BODY_FILE=""
HTTP_HEADER_FILE=""
HTTP_STATUS=""

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_common_commands() {
  require_command az
  require_command curl
  require_command jq
  require_command terraform
}

require_az_extension() {
  AZ_EXTENSION_NAME=$1
  az extension show --name "$AZ_EXTENSION_NAME" --output none >/dev/null 2>&1 \
    || die "Required Azure CLI extension not found: ${AZ_EXTENSION_NAME}. Install it with: az extension add --name ${AZ_EXTENSION_NAME} --yes"
}

terraform_output_value() {
  printf '%s' "$TERRAFORM_OUTPUTS" | jq -r --arg output_name "$1" '
    .[$output_name].value as $value
    | if $value == null then empty
      elif ($value | type) == "string" then $value
      else ($value | tostring)
      end
  '
}

load_terraform_outputs() {
  TERRAFORM_OUTPUTS=$(terraform -chdir="${SCENARIO_DIR}" output -json)

  RESOURCE_GROUP_NAME=$(terraform_output_value resource_group_name)
  API_MANAGEMENT_ID=$(terraform_output_value api_management_id)
  API_MANAGEMENT_NAME=$(terraform_output_value api_management_name)
  CORE_HELLO_URL=$(terraform_output_value core_hello_url)
  CORE_MOCK_URL=$(terraform_output_value core_mock_url)
  CORE_RATE_LIMIT_CALLS=$(terraform_output_value core_rate_limit_calls)
  CORE_RATE_LIMIT_RENEWAL_PERIOD_SECONDS=$(terraform_output_value core_rate_limit_renewal_period_seconds)
  PLAYGROUND_SUBSCRIPTION_KEY=$(terraform_output_value playground_subscription_primary_key)

  BACKEND_POOL_ENABLED=$(terraform_output_value backend_pool_enabled)
  CIRCUIT_BREAKER_ENABLED=$(terraform_output_value circuit_breaker_enabled)
  RESILIENCE_WEIGHTED_URL=$(terraform_output_value resilience_weighted_url)
  RESILIENCE_FAILOVER_URL=$(terraform_output_value resilience_failover_url)

  AI_BACKEND_ENABLED=$(terraform_output_value ai_backend_enabled)
  AI_GATEWAY_URL=$(terraform_output_value ai_gateway_url)
  AI_DEPLOYMENT_NAME=$(terraform_output_value ai_deployment_name)
  AI_REASONING_EFFORT=$(terraform_output_value ai_reasoning_effort)
  LLM_TOKEN_LIMIT_ENABLED=$(terraform_output_value llm_token_limit_enabled)

  CONTENT_SAFETY_ENABLED=$(terraform_output_value content_safety_enabled)
  CONTENT_SAFETY_ENDPOINT=$(terraform_output_value content_safety_endpoint)
  CONTENT_SAFETY_BLOCKLIST_NAME=$(terraform_output_value content_safety_blocklist_name)

  OBSERVABILITY_ENABLED=$(terraform_output_value observability_enabled)
  LOG_ANALYTICS_WORKSPACE_CUSTOMER_ID=$(terraform_output_value log_analytics_workspace_customer_id)
  APPLICATION_INSIGHTS_APP_ID=$(terraform_output_value application_insights_app_id)
  LLM_LOGGING_ENABLED=$(terraform_output_value llm_logging_enabled)
  LLM_TOKEN_METRICS_ENABLED=$(terraform_output_value llm_token_metrics_enabled)

  CONTENT_SAFETY_ENDPOINT=${CONTENT_SAFETY_ENDPOINT%/}
  AI_GATEWAY_URL=${AI_GATEWAY_URL%/}

  AZURE_SUBSCRIPTION_ID=""
  if [ -n "$API_MANAGEMENT_ID" ]; then
    AZURE_SUBSCRIPTION_ID=$(printf '%s' "$API_MANAGEMENT_ID" | cut -d/ -f3)
  fi
}

require_value() {
  VALUE_LABEL=$1
  VALUE_CONTENT=$2
  [ -n "$VALUE_CONTENT" ] || die "Terraform output is empty: ${VALUE_LABEL}. Apply the required profile first."
}

require_feature() {
  FEATURE_LABEL=$1
  FEATURE_VALUE=$2
  [ "$FEATURE_VALUE" = "true" ] || die "Feature is not enabled: ${FEATURE_LABEL}."
}

require_core_outputs() {
  require_value api_management_id "$API_MANAGEMENT_ID"
  require_value core_hello_url "$CORE_HELLO_URL"
  require_value core_mock_url "$CORE_MOCK_URL"
  require_value playground_subscription_primary_key "$PLAYGROUND_SUBSCRIPTION_KEY"
  require_value subscription_id "$AZURE_SUBSCRIPTION_ID"
}

get_access_token() {
  az account get-access-token \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --scope "$1" \
    --query accessToken \
    --output tsv
}

cleanup_http_files() {
  if [ -n "$HTTP_BODY_FILE" ] && [ -f "$HTTP_BODY_FILE" ]; then
    rm -f "$HTTP_BODY_FILE"
  fi
  if [ -n "$HTTP_HEADER_FILE" ] && [ -f "$HTTP_HEADER_FILE" ]; then
    rm -f "$HTTP_HEADER_FILE"
  fi
  HTTP_BODY_FILE=""
  HTTP_HEADER_FILE=""
}

trap 'cleanup_http_files' 0
trap 'cleanup_http_files; exit 1' HUP INT TERM

http_request() {
  cleanup_http_files
  HTTP_BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/apim-playground-body.XXXXXX")
  HTTP_HEADER_FILE=$(mktemp "${TMPDIR:-/tmp}/apim-playground-headers.XXXXXX")

  if HTTP_STATUS=$(curl \
    --silent \
    --show-error \
    --output "$HTTP_BODY_FILE" \
    --dump-header "$HTTP_HEADER_FILE" \
    --write-out '%{http_code}' \
    "$@"); then
    return 0
  fi

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
  die "Unexpected HTTP status ${HTTP_STATUS}; expected one of:$*."
}

response_header() {
  HEADER_NAME=$1
  awk -F ':' -v target="$HEADER_NAME" '
    tolower($1) == tolower(target) {
      sub(/^[^:]*:[[:space:]]*/, "")
      sub(/\r$/, "")
      value = $0
    }
    END { print value }
  ' "$HTTP_HEADER_FILE"
}

json_body_contains_string() {
  EXPECTED_STRING=$1
  jq -e --arg expected "$EXPECTED_STRING" '[.. | strings] | index($expected) != null' "$HTTP_BODY_FILE" >/dev/null
}

url_encode() {
  jq -nr --arg value "$1" '$value | @uri'
}

validate_positive_integer() {
  INTEGER_LABEL=$1
  INTEGER_VALUE=$2
  case "$INTEGER_VALUE" in
    ''|*[!0-9]*) die "${INTEGER_LABEL} must be a positive integer: ${INTEGER_VALUE}" ;;
  esac
  [ "$INTEGER_VALUE" -gt 0 ] || die "${INTEGER_LABEL} must be greater than zero."
}
