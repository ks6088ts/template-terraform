#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${KUBECOST_NAMESPACE:=kubecost}"
: "${KUBECOST_RELEASE:=kubecost}"
: "${KUBECOST_CHART_VERSION:=3.2.4}"
KUBECOST_VALUES="${SCENARIO_DIR}/manifests/kubecost/values.yaml"

require_common_commands
require_command helm
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

run_command helm repo add kubecost https://kubecost.github.io/kubecost/ --force-update
run_command helm repo update kubecost
ensure_workshop_namespace "$KUBECOST_NAMESPACE"
run_command helm upgrade --install \
  "$KUBECOST_RELEASE" \
  kubecost/kubecost \
  --namespace "$KUBECOST_NAMESPACE" \
  --version "$KUBECOST_CHART_VERSION" \
  --values "$KUBECOST_VALUES" \
  --set-string "global.clusterId=${AKS_NAME}" \
  --atomic \
  --wait \
  --timeout "$HELM_WAIT_TIMEOUT"

if [ "$DRY_RUN" != "true" ]; then
  kubectl wait pods \
    --namespace "$KUBECOST_NAMESPACE" \
    --selector "app.kubernetes.io/instance=${KUBECOST_RELEASE}" \
    --for=condition=Ready \
    --timeout="$HELM_WAIT_TIMEOUT"

  UNBOUND_PVC_COUNT=$(kubectl get persistentvolumeclaim \
    --namespace "$KUBECOST_NAMESPACE" \
    --output json \
    | jq '[.items[] | select(.status.phase != "Bound")] | length')
  [ "$UNBOUND_PVC_COUNT" -eq 0 ] \
    || die "Kubecost has ${UNBOUND_PVC_COUNT} unbound PersistentVolumeClaims."

  KUBECOST_SERVICE=$(kubectl get service \
    --namespace "$KUBECOST_NAMESPACE" \
    --output json \
    | jq -r '[.items[] | select(any(.spec.ports[]?; .port == 9090)) | .metadata.name][0] // empty')
  [ -n "$KUBECOST_SERVICE" ] || die "Kubecost frontend Service was not found."
fi

log "Kubecost workshop is ready."
if [ "${KUBECOST_SERVICE:-}" ]; then
  log "UI: kubectl port-forward -n ${KUBECOST_NAMESPACE} svc/${KUBECOST_SERVICE} 9090:9090"
fi
log "Cost data requires time to accumulate. Cloud billing integration is outside this workshop."
