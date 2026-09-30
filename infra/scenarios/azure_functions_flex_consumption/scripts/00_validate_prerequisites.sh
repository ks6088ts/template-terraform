#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_common.sh"

[ "$#" -eq 0 ] || die "Usage: 00_validate_prerequisites.sh"
require_command az
require_command curl
load_outputs
require_output "$FUNCTION_APP_URL" function_app_url
require_output "$AUTH_IDENTIFIER_URI" function_app_authentication_identifier_uri
require_output "$STORAGE_ACCOUNT_NAME" storage_account_name
require_output "$DEPLOYMENT_CONTAINER_NAME" deployment_container_name
require_output "$WORKSPACE_ID" log_analytics_workspace_customer_id
require_output "$APP_INSIGHTS_APP_ID" application_insights_app_id
require_output "$TIMER_SCHEDULE" timer_schedule
printf 'Prerequisites verified for subscription %s.\n' "$SUBSCRIPTION_ID"
