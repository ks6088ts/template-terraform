#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

ACTION=${1:-status}

require_common_commands
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
fi

show_status() {
  run_command az aks show \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --query '{Name:name,PowerState:powerState.code,ProvisioningState:provisioningState,KubernetesVersion:currentKubernetesVersion}' \
    --output table
}

current_power_state() {
  az aks show \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --query powerState.code \
    --output tsv
}

case "$ACTION" in
  status)
    show_status
    ;;
  start)
    if [ "$DRY_RUN" = "true" ]; then
      print_command az aks start \
        --subscription "$AZURE_SUBSCRIPTION_ID" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$AKS_NAME"
    elif [ "$(current_power_state)" = "Running" ]; then
      log "AKS cluster is already running: ${AKS_NAME}"
    else
      az aks start \
        --subscription "$AZURE_SUBSCRIPTION_ID" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$AKS_NAME" \
        --output none
      wait_for_aks_power_state Running
    fi
    ;;
  stop)
    [ "${CONFIRM_STOP:-}" = "stop-aks-workshop-cluster" ] \
      || die "Set CONFIRM_STOP=stop-aks-workshop-cluster to stop the AKS cluster."

    if [ "$DRY_RUN" = "true" ]; then
      print_command az aks stop \
        --subscription "$AZURE_SUBSCRIPTION_ID" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$AKS_NAME"
    elif [ "$(current_power_state)" = "Stopped" ]; then
      log "AKS cluster is already stopped: ${AKS_NAME}"
    else
      az aks stop \
        --subscription "$AZURE_SUBSCRIPTION_ID" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --name "$AKS_NAME" \
        --output none
      wait_for_aks_power_state Stopped
    fi
    ;;
  *)
    die "Unsupported action: ${ACTION}. Use status, start, or stop."
    ;;
esac

log "AKS cluster action completed: ${ACTION}"
