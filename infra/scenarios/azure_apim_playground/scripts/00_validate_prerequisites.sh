#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_core_outputs

az account show --subscription "$AZURE_SUBSCRIPTION_ID" --output none

if [ "$CONTENT_SAFETY_ENABLED" = "true" ]; then
  require_value content_safety_endpoint "$CONTENT_SAFETY_ENDPOINT"
  require_value content_safety_blocklist_name "$CONTENT_SAFETY_BLOCKLIST_NAME"
  CONTENT_SAFETY_TOKEN=$(get_access_token "https://cognitiveservices.azure.com/.default")
  [ -n "$CONTENT_SAFETY_TOKEN" ] || die "Azure CLI returned an empty Content Safety access token."
  CONTENT_SAFETY_TOKEN=""
fi

if [ "$AI_BACKEND_ENABLED" = "true" ]; then
  require_value ai_gateway_url "$AI_GATEWAY_URL"
  require_value ai_deployment_name "$AI_DEPLOYMENT_NAME"
fi

if [ "$OBSERVABILITY_ENABLED" = "true" ]; then
  require_value log_analytics_workspace_customer_id "$LOG_ANALYTICS_WORKSPACE_CUSTOMER_ID"
  require_value application_insights_app_id "$APPLICATION_INSIGHTS_APP_ID"
fi

if [ "$LLM_LOGGING_ENABLED" = "true" ] || [ "$LLM_TOKEN_METRICS_ENABLED" = "true" ]; then
  require_az_extension log-analytics
fi

log "Prerequisite validation succeeded."
log "Subscription: ${AZURE_SUBSCRIPTION_ID}"
log "Resource group: ${RESOURCE_GROUP_NAME}"
log "API Management: ${API_MANAGEMENT_NAME}"
log "Backend pool: ${BACKEND_POOL_ENABLED}"
log "Circuit breaker: ${CIRCUIT_BREAKER_ENABLED}"
log "AI gateway: ${AI_BACKEND_ENABLED}"
log "Content Safety: ${CONTENT_SAFETY_ENABLED}"
log "Observability: ${OBSERVABILITY_ENABLED}"
log "LLM logs: ${LLM_LOGGING_ENABLED}"
log "LLM token metrics: ${LLM_TOKEN_METRICS_ENABLED}"
