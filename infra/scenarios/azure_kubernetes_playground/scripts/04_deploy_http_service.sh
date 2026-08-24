#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${HTTP_NAMESPACE:=workshop-http}"
: "${HTTP_SOURCE_IMAGE:=docker.io/ks6088ts/workshop-kubernetes:0.0.5}"
: "${HTTP_ACR_IMAGE:=workshop-kubernetes:0.0.5}"
: "${HTTP_ROUTE_HOSTNAME:=http-server.workshop.local}"
MANIFEST_DIR="${SCENARIO_DIR}/manifests/http-server"

require_common_commands
require_command curl
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
  kubectl get gateway "$GATEWAY_NAME" \
    --namespace "$GATEWAY_NAMESPACE" \
    >/dev/null
fi

run_command az acr import \
  --subscription "$AZURE_SUBSCRIPTION_ID" \
  --name "$ACR_NAME" \
  --source "$HTTP_SOURCE_IMAGE" \
  --image "$HTTP_ACR_IMAGE" \
  --force \
  --only-show-errors \
  --output none

ensure_workshop_namespace "$HTTP_NAMESPACE"
run_command kubectl apply \
  --namespace "$HTTP_NAMESPACE" \
  --filename "${MANIFEST_DIR}/deployment.yaml"
run_command kubectl apply \
  --namespace "$HTTP_NAMESPACE" \
  --filename "${MANIFEST_DIR}/service.yaml"
run_command kubectl apply \
  --namespace "$HTTP_NAMESPACE" \
  --filename "${MANIFEST_DIR}/httproute.yaml"
run_command kubectl set image \
  "deployment/http-server" \
  "http-server=${ACR_LOGIN_SERVER}/${HTTP_ACR_IMAGE}" \
  --namespace "$HTTP_NAMESPACE"

if [ "$DRY_RUN" != "true" ]; then
  kubectl rollout status deployment/http-server \
    --namespace "$HTTP_NAMESPACE" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"
  kubectl wait \
    --for=condition=Accepted \
    httproute/http-server \
    --namespace "$HTTP_NAMESPACE" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"
  kubectl wait \
    --for=condition=ResolvedRefs \
    httproute/http-server \
    --namespace "$HTTP_NAMESPACE" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"

  GATEWAY_ADDRESS=$(kubectl get gateway "$GATEWAY_NAME" \
    --namespace "$GATEWAY_NAMESPACE" \
    --output jsonpath='{.status.addresses[0].value}')
  curl --fail --silent --show-error \
    --header "Host: ${HTTP_ROUTE_HOSTNAME}" \
    "http://${GATEWAY_ADDRESS}/healthz" \
    >/dev/null
  curl --fail --silent --show-error \
    --header "Host: ${HTTP_ROUTE_HOSTNAME}" \
    "http://${GATEWAY_ADDRESS}/metrics" \
    >/dev/null

  if kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
    kubectl apply \
      --namespace "$HTTP_NAMESPACE" \
      --filename "${MANIFEST_DIR}/servicemonitor.yaml"
  else
    log "ServiceMonitor CRD is not installed; the monitoring lab will add the HTTP target later."
  fi
fi

log "HTTP workshop is ready."
log "Image: ${ACR_LOGIN_SERVER}/${HTTP_ACR_IMAGE}"
if [ "${GATEWAY_ADDRESS:-}" ]; then
  log "Test URL: http://${GATEWAY_ADDRESS}/ with Host header ${HTTP_ROUTE_HOSTNAME}"
fi
