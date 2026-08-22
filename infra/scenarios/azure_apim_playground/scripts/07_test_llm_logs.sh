#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_feature llm_logging "$LLM_LOGGING_ENABLED"
require_value log_analytics_workspace_customer_id "$LOG_ANALYTICS_WORKSPACE_CUSTOMER_ID"
require_az_extension log-analytics
validate_positive_integer LOG_QUERY_ATTEMPTS "$LOG_QUERY_ATTEMPTS"
validate_positive_integer LOG_QUERY_INTERVAL_SECONDS "$LOG_QUERY_INTERVAL_SECONDS"

LLM_LOG_QUERY='union isfuzzy=true ApiManagementGatewayLlmLog
| where TimeGenerated > ago(24h)
| summarize Records = count()'

ATTEMPT=1
RECORD_COUNT=0
while [ "$ATTEMPT" -le "$LOG_QUERY_ATTEMPTS" ]; do
  log "Querying API Management LLM logs (${ATTEMPT}/${LOG_QUERY_ATTEMPTS})."
  if QUERY_RESULT=$(az monitor log-analytics query \
    --workspace "$LOG_ANALYTICS_WORKSPACE_CUSTOMER_ID" \
    --analytics-query "$LLM_LOG_QUERY" \
    --output json); then
    RECORD_COUNT=$(printf '%s' "$QUERY_RESULT" | jq -r '.[0].Records // 0')
  else
    die "Log Analytics query for API Management LLM logs failed."
  fi

  if [ "$RECORD_COUNT" -gt 0 ]; then
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  if [ "$ATTEMPT" -le "$LOG_QUERY_ATTEMPTS" ]; then
    log "No API Management LLM logs found yet; retrying in ${LOG_QUERY_INTERVAL_SECONDS} seconds."
    sleep "$LOG_QUERY_INTERVAL_SECONDS"
  fi
done

[ "$RECORD_COUNT" -gt 0 ] \
  || die "No ApiManagementGatewayLlmLog records were found after ${LOG_QUERY_ATTEMPTS} queries. Run an AI gateway request and allow for ingestion delay."

log "Azure Monitor contains ${RECORD_COUNT} recent API Management LLM log records."
