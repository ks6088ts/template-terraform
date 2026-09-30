#!/bin/sh

# shellcheck disable=SC2034
set -eu

SCENARIO_DIR=$(CDPATH='' cd "$SCRIPT_DIR/.." && pwd)

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

output_value() {
  printf '%s' "$OUTPUTS" | jq -r --arg name "$1" '.[$name].value // empty | strings'
}

require_active_subscription() {
  require_command az
  ACTIVE_SUBSCRIPTION=$(az account show --query id --output tsv) ||
    die "Azure CLI is not signed in."
  [ "$ACTIVE_SUBSCRIPTION" = "$SUBSCRIPTION_ID" ] ||
    die "Azure CLI active subscription differs from the Terraform subscription."
}

load_outputs() {
  require_command terraform
  require_command jq
  OUTPUTS=$(terraform -chdir="$SCENARIO_DIR" output -json) ||
    die "Cannot read Terraform outputs; apply the scenario first."
  SUBSCRIPTION_ID=$(output_value subscription_id)
  RESOURCE_GROUP_NAME=$(output_value resource_group_name)
  FUNCTION_APP_NAME=$(output_value function_app_name)
  FUNCTION_APP_ID=$(output_value function_app_id)
  FUNCTION_APP_URL=$(output_value function_app_url)
  AUTH_IDENTIFIER_URI=$(output_value function_app_authentication_identifier_uri)
  STORAGE_ACCOUNT_NAME=$(output_value storage_account_name)
  DEPLOYMENT_CONTAINER_NAME=$(output_value deployment_container_name)
  WORKSPACE_ID=$(output_value log_analytics_workspace_customer_id)
  APP_INSIGHTS_APP_ID=$(output_value application_insights_app_id)
  TIMER_SCHEDULE=$(output_value timer_schedule)
  [ -n "$SUBSCRIPTION_ID" ] || die "Missing subscription_id output."
  [ -n "$RESOURCE_GROUP_NAME" ] || die "Missing resource_group_name output."
  [ -n "$FUNCTION_APP_NAME" ] || die "Missing function_app_name output."
  [ -n "$FUNCTION_APP_ID" ] || die "Missing function_app_id output."
  case "$FUNCTION_APP_ID" in
    "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME") ;;
    *) die "Function App ID does not match the subscription, resource group and name outputs." ;;
  esac
  require_active_subscription
}

require_output() {
  [ -n "$1" ] || die "Missing required Terraform output: $2."
}

init_response_file() {
  umask 077
  RESPONSE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/flex-verify.XXXXXX") ||
    die "Cannot create response directory."
  RESPONSE_FILE="$RESPONSE_DIR/response"
  trap 'rm -rf "$RESPONSE_DIR"' 0
  trap 'exit 1' 1 2 3 15
}

request() {
  HTTP_STATUS=$(curl --silent --show-error --max-time 30 --output "$RESPONSE_FILE" \
    --write-out '%{http_code}' "$@") || die "HTTP request failed."
}

expect_status() {
  [ "$HTTP_STATUS" = "$1" ] || die "Expected HTTP $1; received HTTP $HTTP_STATUS."
}

access_token() {
  require_command az
  ACCESS_TOKEN=$(az account get-access-token --subscription "$SUBSCRIPTION_ID" \
    --resource "$AUTH_IDENTIFIER_URI" --query accessToken --output tsv) ||
    die "Cannot acquire an access token for the Function App."
  case "$ACCESS_TOKEN" in
    ''|None) die "Azure CLI returned an empty access token." ;;
  esac
}

function_key() {
  require_command az
  FUNCTION_KEY=$(az functionapp function keys list \
    --subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$FUNCTION_APP_NAME" --function-name hello_world_http_with_function_key \
    --query default --output tsv) || die "Cannot retrieve the Function key."
  case "$FUNCTION_KEY" in
    ''|None) die "Azure CLI returned an empty Function key." ;;
  esac
}

query_telemetry() {
  require_command az
  require_output "$APP_INSIGHTS_APP_ID" application_insights_app_id
  APP_INSIGHTS_API_ENDPOINT=$(az cloud show \
    --query endpoints.appInsightsResourceId --output tsv) ||
    die "Cannot determine the Application Insights API endpoint."
  case "$APP_INSIGHTS_API_ENDPOINT" in
    https://*) APP_INSIGHTS_API_ENDPOINT=${APP_INSIGHTS_API_ENDPOINT%/} ;;
    *) die "Azure CLI returned an invalid Application Insights API endpoint." ;;
  esac
  QUERY_BODY=$(jq -cn --arg query "$1" '{query: $query}') ||
    die "Cannot encode the Application Insights query."
  az rest --subscription "$SUBSCRIPTION_ID" --method post \
    --url "$APP_INSIGHTS_API_ENDPOINT/v1/apps/$APP_INSIGHTS_APP_ID/query" \
    --resource "$APP_INSIGHTS_API_ENDPOINT" --body "$QUERY_BODY" --output json
}

has_telemetry_rows() {
  jq -e 'any(.tables[]?.rows[]?; true)' >/dev/null
}
