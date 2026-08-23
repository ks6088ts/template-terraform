#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
validate_configuration
load_terraform_outputs
require_scenario_outputs
: "${MIN_READY_NODES:=1}"
validate_positive_integer MIN_READY_NODES "$MIN_READY_NODES"

if [ "$DRY_RUN" = "true" ]; then
  print_command az aks get-credentials \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --overwrite-existing
  print_command kubectl cluster-info
  print_command kubectl wait nodes --all --for=condition=Ready --timeout="$KUBECTL_WAIT_TIMEOUT"
  print_command kubectl get nodes --output wide
  print_command az aks check-acr \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --acr "$ACR_NAME"
else
  require_target_subscription
  AKS_POWER_STATE=$(az aks show \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --query powerState.code \
    --output tsv)
  [ "$AKS_POWER_STATE" = "Running" ] \
    || die "AKS cluster is ${AKS_POWER_STATE}. Start it with 02_manage_cluster.sh start."

  az aks get-credentials \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --overwrite-existing
  require_cluster_context
  kubectl cluster-info
  kubectl wait nodes --all --for=condition=Ready --timeout="$KUBECTL_WAIT_TIMEOUT"
  kubectl get nodes --output wide

  READY_NODE_COUNT=$(kubectl get nodes --output json | jq '[
    .items[]
    | select(.status.conditions | any(.type == "Ready" and .status == "True"))
  ] | length')
  [ "$READY_NODE_COUNT" -ge "$MIN_READY_NODES" ] \
    || die "Only ${READY_NODE_COUNT} Ready nodes found; expected at least ${MIN_READY_NODES}."

  az aks nodepool list \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --cluster-name "$AKS_NAME" \
    --query '[].{Name:name,Mode:mode,Count:count,VMSize:vmSize}' \
    --output table
  az aks check-acr \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --acr "$ACR_NAME"
  kubectl get storageclass
  kubectl get deployment metrics-server --namespace kube-system
fi

log "Connected to AKS cluster: ${AKS_NAME}"
log "Ready nodes: ${MIN_READY_NODES} or more"
log "Validated ACR access: ${ACR_LOGIN_SERVER}"
