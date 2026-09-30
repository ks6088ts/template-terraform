#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_common.sh"

[ "$#" -eq 0 ] || die "Usage: 04_test_timer.sh"
load_outputs
require_command az
require_output "$TIMER_SCHEDULE" timer_schedule
require_output "$WORKSPACE_ID" log_analytics_workspace_customer_id
require_output "$APP_INSIGHTS_APP_ID" application_insights_app_id
ACTUAL_SCHEDULE=$(az functionapp function show --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP_NAME" --name "$FUNCTION_APP_NAME" \
  --function-name hello_world_timer \
  --query "config.bindings[?type=='timerTrigger'].schedule | [0]" --output tsv) ||
  die "Cannot inspect deployed timer trigger."
case "$ACTUAL_SCHEDULE" in
  '%TIMER_SCHEDULE%')
    APP_SETTING=$(az functionapp config appsettings list --subscription "$SUBSCRIPTION_ID" \
      --resource-group "$RESOURCE_GROUP_NAME" --name "$FUNCTION_APP_NAME" \
      --query "[?name=='TIMER_SCHEDULE'].value | [0]" --output tsv) ||
      die "Cannot inspect deployed timer app setting."
    [ "$APP_SETTING" = "$TIMER_SCHEDULE" ] ||
      die "Deployed timer app setting differs from Terraform output."
    ;;
  "$TIMER_SCHEDULE") ;;
  *) die "Deployed timer schedule differs from Terraform output." ;;
esac
# Query the target Application Insights app, not an unscoped workspace shared by other apps.
attempt=1
while [ "$attempt" -le 6 ]; do
  QUERY_ENDED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  QUERY="traces | where timestamp >= ago(24h) | where timestamp <= datetime('$QUERY_ENDED_AT') | where message contains 'flex-timer-check: completed' | take 1"
  RESULT=$(query_telemetry "$QUERY") || die "Timer telemetry query failed."
  if printf '%s' "$RESULT" | has_telemetry_rows; then
    printf 'Timer schedule and execution trace verified.\n'
    exit 0
  fi
  [ "$attempt" -eq 6 ] || sleep 10
  attempt=$((attempt + 1))
done
die "No timer trace in the last 24 hours. Confirm code was published, wait for the next scheduled timer run and telemetry ingestion, then retry."
