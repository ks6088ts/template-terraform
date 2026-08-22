#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_feature llm_token_metrics "$LLM_TOKEN_METRICS_ENABLED"
require_value log_analytics_workspace_customer_id "$LOG_ANALYTICS_WORKSPACE_CUSTOMER_ID"
require_az_extension log-analytics
validate_positive_integer LOG_QUERY_ATTEMPTS "$LOG_QUERY_ATTEMPTS"
validate_positive_integer LOG_QUERY_INTERVAL_SECONDS "$LOG_QUERY_INTERVAL_SECONDS"

TOKEN_METRIC_QUERY='union isfuzzy=true AppMetrics
| where TimeGenerated > ago(24h)
| summarize Records = count(), MetricNames = make_set(Name, 20)'

ATTEMPT=1
RECORD_COUNT=0
METRIC_NAMES=""
while [ "$ATTEMPT" -le "$LOG_QUERY_ATTEMPTS" ]; do
  log "Querying Application Insights custom metrics (${ATTEMPT}/${LOG_QUERY_ATTEMPTS})."
  if QUERY_RESULT=$(az monitor log-analytics query \
    --workspace "$LOG_ANALYTICS_WORKSPACE_CUSTOMER_ID" \
    --analytics-query "$TOKEN_METRIC_QUERY" \
    --output json); then
    RECORD_COUNT=$(printf '%s' "$QUERY_RESULT" | jq -r '.[0].Records // 0')
    METRIC_NAMES=$(printf '%s' "$QUERY_RESULT" | jq -r '
      .[0].MetricNames // []
      | if type == "string" then fromjson else . end
      | join(", ")
    ')
  else
    die "Log Analytics query for Application Insights custom metrics failed."
  fi

  if [ "$RECORD_COUNT" -gt 0 ]; then
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  if [ "$ATTEMPT" -le "$LOG_QUERY_ATTEMPTS" ]; then
    log "No Application Insights custom metrics found yet; retrying in ${LOG_QUERY_INTERVAL_SECONDS} seconds."
    sleep "$LOG_QUERY_INTERVAL_SECONDS"
  fi
done

[ "$RECORD_COUNT" -gt 0 ] \
  || die "No Application Insights custom metrics were found after ${LOG_QUERY_ATTEMPTS} queries. Run an AI gateway request and allow for ingestion delay."

log "Application Insights contains ${RECORD_COUNT} recent custom metric records."
if [ -n "$METRIC_NAMES" ]; then
  log "Metric names: ${METRIC_NAMES}"
fi
