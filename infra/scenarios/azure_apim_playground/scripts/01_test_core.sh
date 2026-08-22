#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_core_outputs
validate_positive_integer core_rate_limit_calls "$CORE_RATE_LIMIT_CALLS"

http_request \
  --request GET \
  "$CORE_HELLO_URL" \
  --header "Ocp-Apim-Subscription-Key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Accept: application/json"
expect_http_status 200
jq -e '
  .message == "hello from Azure API Management"
  and .source == "policy"
' "$HTTP_BODY_FILE" >/dev/null || die "Core hello response did not match the deterministic policy payload."
[ "$(response_header x-apim-playground)" = "azure_apim_playground" ] \
  || die "Core hello response is missing the playground marker header."
log "Core hello policy returned the expected payload."

http_request \
  --request GET \
  "$CORE_MOCK_URL" \
  --header "Ocp-Apim-Subscription-Key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Accept: application/json"
expect_http_status 200
jq -e '
  .message == "mocked by Azure API Management"
  and .source == "mock-response"
' "$HTTP_BODY_FILE" >/dev/null || die "Core mock response did not match the OpenAPI example."
log "Core mock-response policy returned the expected payload."

RATE_LIMIT_ATTEMPTS=$((CORE_RATE_LIMIT_CALLS + 2))
ATTEMPT=1
RATE_LIMIT_OBSERVED=false
while [ "$ATTEMPT" -le "$RATE_LIMIT_ATTEMPTS" ]; do
  http_request \
    --request GET \
    "$CORE_HELLO_URL" \
    --header "Ocp-Apim-Subscription-Key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
    --header "Accept: application/json"

  case "$HTTP_STATUS" in
    200)
      ;;
    429)
      RATE_LIMIT_OBSERVED=true
      break
      ;;
    *)
      print_http_body >&2
      die "Core rate-limit exercise returned unexpected HTTP status ${HTTP_STATUS}."
      ;;
  esac
  ATTEMPT=$((ATTEMPT + 1))
done

[ "$RATE_LIMIT_OBSERVED" = "true" ] \
  || die "Core rate limit did not return 429 within ${RATE_LIMIT_ATTEMPTS} requests."
log "Core subscription rate limit returned HTTP 429 as configured."
