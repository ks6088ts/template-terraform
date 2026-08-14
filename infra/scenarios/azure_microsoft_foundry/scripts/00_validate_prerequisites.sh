#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
require_model_deployment "$AGENT_MODEL"
require_model_deployment "$EMBEDDING_DEPLOYMENT"

[ -f "$RESTAURANT_DATA_FILE" ] || die "Restaurant data file not found: ${RESTAURANT_DATA_FILE}"

az account show --subscription "$AZURE_SUBSCRIPTION_ID" --output none

check_token_scope() {
  TOKEN_LABEL=$1
  TOKEN_SCOPE=$2
  ACCESS_TOKEN=$(get_access_token "$TOKEN_SCOPE")
  [ -n "$ACCESS_TOKEN" ] || die "Azure CLI returned an empty ${TOKEN_LABEL} access token."
  ACCESS_TOKEN=""
  log "Validated ${TOKEN_LABEL} token acquisition."
}

check_token_scope "Azure Storage" "https://storage.azure.com/.default"
check_token_scope "Azure AI Search" "https://search.azure.com/.default"
check_token_scope "Azure Resource Manager" "https://management.azure.com/.default"
check_token_scope "Microsoft Foundry" "https://ai.azure.com/.default"

log "Prerequisite validation succeeded."
log "Subscription: ${AZURE_SUBSCRIPTION_ID}"
log "Resource group: ${RESOURCE_GROUP_NAME}"
log "Foundry project: ${PROJECT_NAME}"
log "Search service: ${SEARCH_NAME}"
log "Storage account: ${STORAGE_ACCOUNT_NAME}"
log "Operator principal: ${OPERATOR_PRINCIPAL_ID}"
log "Agent model: ${AGENT_MODEL}"
log "Embedding model: ${EMBEDDING_DEPLOYMENT}"
log "Restaurant data: ${RESTAURANT_DATA_FILE}"