#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${BACKEND_REQUESTS:=24}"

require_common_commands
load_terraform_outputs
require_core_outputs
require_feature backend_pool "$BACKEND_POOL_ENABLED"
require_value resilience_weighted_url "$RESILIENCE_WEIGHTED_URL"
validate_positive_integer BACKEND_REQUESTS "$BACKEND_REQUESTS"

PRIMARY_COUNT=0
SECONDARY_COUNT=0
ATTEMPT=1
while [ "$ATTEMPT" -le "$BACKEND_REQUESTS" ]; do
  http_request \
    --request GET \
    "$RESILIENCE_WEIGHTED_URL" \
    --header "Ocp-Apim-Subscription-Key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
    --header "Accept: application/json"
  expect_http_status 200

  if json_body_contains_string primary; then
    PRIMARY_COUNT=$((PRIMARY_COUNT + 1))
  elif json_body_contains_string secondary; then
    SECONDARY_COUNT=$((SECONDARY_COUNT + 1))
  else
    print_http_body >&2
    die "Weighted response did not identify the selected backend."
  fi
  ATTEMPT=$((ATTEMPT + 1))
done

[ "$PRIMARY_COUNT" -gt 0 ] || die "Weighted routing did not select the primary backend."
[ "$SECONDARY_COUNT" -gt 0 ] || die "Weighted routing did not select the secondary backend."

log "Weighted routing reached both backends across ${BACKEND_REQUESTS} requests."
log "Primary responses: ${PRIMARY_COUNT}"
log "Secondary responses: ${SECONDARY_COUNT}"
