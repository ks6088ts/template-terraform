#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${FAILOVER_ATTEMPTS:=12}"

require_common_commands
load_terraform_outputs
require_core_outputs
require_feature circuit_breaker "$CIRCUIT_BREAKER_ENABLED"
require_value resilience_failover_url "$RESILIENCE_FAILOVER_URL"
validate_positive_integer FAILOVER_ATTEMPTS "$FAILOVER_ATTEMPTS"

PRIMARY_FAILURES=0
SECONDARY_RESPONSES=0
ATTEMPT=1
while [ "$ATTEMPT" -le "$FAILOVER_ATTEMPTS" ]; do
  http_request \
    --request GET \
    "$RESILIENCE_FAILOVER_URL" \
    --header "Ocp-Apim-Subscription-Key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
    --header "Accept: application/json"

  case "$HTTP_STATUS" in
    503)
      PRIMARY_FAILURES=$((PRIMARY_FAILURES + 1))
      ;;
    200)
      if json_body_contains_string secondary; then
        SECONDARY_RESPONSES=$((SECONDARY_RESPONSES + 1))
      else
        print_http_body >&2
        die "Failover returned 200 without identifying the secondary backend."
      fi
      ;;
    *)
      print_http_body >&2
      die "Failover exercise returned unexpected HTTP status ${HTTP_STATUS}."
      ;;
  esac

  if [ "$SECONDARY_RESPONSES" -gt 0 ]; then
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  sleep 1
done

[ "$SECONDARY_RESPONSES" -gt 0 ] \
  || die "Circuit breaker did not route to the priority secondary within ${FAILOVER_ATTEMPTS} requests."

log "Circuit-breaker failover reached the priority secondary backend."
log "Observed primary 503 responses before failover: ${PRIMARY_FAILURES}"
