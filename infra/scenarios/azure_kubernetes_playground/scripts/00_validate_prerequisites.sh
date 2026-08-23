#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
require_command curl
require_command helm
require_command openssl
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" = "true" ]; then
  print_command az account show --output none
  print_command az aks show \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --output none
else
  az account show --output none
  require_target_subscription
  AKS_PROVISIONING_STATE=$(az aks show \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --query provisioningState \
    --output tsv)
  [ "$AKS_PROVISIONING_STATE" = "Succeeded" ] \
    || die "AKS provisioning state is ${AKS_PROVISIONING_STATE}; expected Succeeded."
fi

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
AZURE_CLI_VERSION=$(az version --query '"azure-cli"' --output tsv)
KUBECTL_VERSION=$(kubectl version --client --output json | jq -r '.clientVersion.gitVersion')
HELM_VERSION=$(helm version --short)

log "Prerequisite validation succeeded."
log "Terraform: ${TERRAFORM_VERSION}"
log "Azure CLI: ${AZURE_CLI_VERSION}"
log "kubectl: ${KUBECTL_VERSION}"
log "Helm: ${HELM_VERSION}"
log "Subscription: ${AZURE_SUBSCRIPTION_ID}"
log "Resource group: ${RESOURCE_GROUP_NAME}"
log "AKS cluster: ${AKS_NAME}"
log "Container registry: ${ACR_LOGIN_SERVER}"
