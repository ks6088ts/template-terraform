#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

MANIFEST_DIR="${SCENARIO_DIR}/manifests/gateway"
: "${MINIMUM_AZURE_CLI_VERSION:=2.86.0}"

require_common_commands
validate_configuration
load_terraform_outputs
require_scenario_outputs

AZURE_CLI_VERSION=$(az version --query '"azure-cli"' --output tsv)
version_at_least "$AZURE_CLI_VERSION" "$MINIMUM_AZURE_CLI_VERSION" \
  || die "Azure CLI ${MINIMUM_AZURE_CLI_VERSION} or later is required; found ${AZURE_CLI_VERSION}."

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context

  if kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
    GATEWAY_API_CHANNEL=$(kubectl get crd gateways.gateway.networking.k8s.io \
      -o jsonpath='{.metadata.annotations.gateway\.networking\.k8s\.io/channel}')
    [ "$GATEWAY_API_CHANNEL" != "experimental" ] \
      || die "Remove the experimental Gateway API CRDs before enabling AKS Managed Gateway API."
  fi
fi

if [ "$DRY_RUN" = "true" ]; then
  print_command az aks update \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --enable-gateway-api
  print_command az aks update \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --enable-app-routing-istio
  print_command kubectl apply --filename "${MANIFEST_DIR}/namespace.yaml"
  print_command kubectl apply --filename "${MANIFEST_DIR}/gateway.yaml"
else
  az aks update \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --enable-gateway-api \
    --only-show-errors \
    --output none

  kubectl wait \
    --for=condition=Established \
    crd/gateways.gateway.networking.k8s.io \
    --timeout="$KUBECTL_WAIT_TIMEOUT"

  az aks update \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --enable-app-routing-istio \
    --only-show-errors \
    --output none

  kubectl wait \
    --for=condition=Accepted \
    "gatewayclass/${GATEWAY_CLASS_NAME}" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"
  kubectl rollout status \
    deployment/istiod \
    --namespace aks-istio-system \
    --timeout="$KUBECTL_WAIT_TIMEOUT"

  kubectl apply --filename "${MANIFEST_DIR}/namespace.yaml"
  kubectl apply --filename "${MANIFEST_DIR}/gateway.yaml"
  kubectl wait \
    --for=condition=Programmed \
    "gateway/${GATEWAY_NAME}" \
    --namespace "$GATEWAY_NAMESPACE" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"

  GATEWAY_ADDRESS=$(kubectl get gateway "$GATEWAY_NAME" \
    --namespace "$GATEWAY_NAMESPACE" \
    --output jsonpath='{.status.addresses[0].value}')
  [ -n "$GATEWAY_ADDRESS" ] || die "The workshop Gateway does not have an address."

  MANAGED_BY=$(kubectl get crd gateways.gateway.networking.k8s.io \
    --output jsonpath='{.metadata.annotations.app\.kubernetes\.io/managed-by}')
  [ "$MANAGED_BY" = "aks" ] || die "Gateway API CRDs are not managed by AKS."
fi

log "AKS Managed Gateway API is ready."
log "GatewayClass: ${GATEWAY_CLASS_NAME}"
if [ "${GATEWAY_ADDRESS:-}" ]; then
  log "Shared Gateway address: ${GATEWAY_ADDRESS}"
fi
