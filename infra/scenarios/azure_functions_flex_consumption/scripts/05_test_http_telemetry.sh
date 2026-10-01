#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_common.sh"

[ "$#" -eq 0 ] || die "Usage: 05_test_http_telemetry.sh"
load_outputs
require_output "$WORKSPACE_ID" log_analytics_workspace_customer_id
require_output "$FUNCTION_APP_URL" function_app_url
require_command curl
init_response_file
PROBE_STARTED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
if [ -n "$AUTH_IDENTIFIER_URI" ]; then
  access_token
  request --header "Authorization: Be""arer $ACCESS_TOKEN" "$FUNCTION_APP_URL/api/hello?name=Telemetry"
else
  request "$FUNCTION_APP_URL/api/hello?name=Telemetry"
fi
expect_status 200
[ "$(cat "$RESPONSE_FILE")" = 'Hello, Telemetry!' ] ||
  die "Unexpected telemetry probe response."
attempt=1
while [ "$attempt" -le 6 ]; do
  QUERY_ENDED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  QUERY="dependencies | where timestamp >= (datetime('$PROBE_STARTED_AT') - 5s) | where timestamp <= datetime('$QUERY_ENDED_AT') | where name == 'flex-otel-check' | take 1"
  RESULT=$(query_telemetry "$QUERY") || die "OpenTelemetry span query failed."
  if printf '%s' "$RESULT" | has_telemetry_rows; then
    printf 'OpenTelemetry span verified for Application Insights app %s.\n' "$APP_INSIGHTS_APP_ID"
    exit 0
  fi
  [ "$attempt" -eq 6 ] || sleep 10
  attempt=$((attempt + 1))
done
die "No flex-otel-check span appeared for the probe started at $PROBE_STARTED_AT within bounded retries."
