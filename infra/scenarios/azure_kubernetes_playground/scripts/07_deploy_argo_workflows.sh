#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${ARGO_WORKFLOWS_NAMESPACE:=argo}"
: "${ARGO_WORKFLOWS_RELEASE:=argo-workflows}"
: "${ARGO_WORKFLOWS_CHART_VERSION:=2.0.2}"
: "${WORKFLOW_NAMESPACE:=workshop-workflows}"
ARGO_WORKFLOWS_VALUES="${SCENARIO_DIR}/manifests/argo-workflows/values.yaml"
HELLO_WORLD_WORKFLOW="${SCENARIO_DIR}/manifests/argo-workflows/hello-world.yaml"

require_common_commands
require_command helm
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

run_command helm repo add argo https://argoproj.github.io/argo-helm --force-update
run_command helm repo update argo
helm_upgrade_install \
  "$ARGO_WORKFLOWS_RELEASE" \
  argo/argo-workflows \
  "$ARGO_WORKFLOWS_NAMESPACE" \
  "$ARGO_WORKFLOWS_CHART_VERSION" \
  "$ARGO_WORKFLOWS_VALUES"

ensure_workshop_namespace "$WORKFLOW_NAMESPACE"
run_command kubectl delete workflow hello-world \
  --namespace "$WORKFLOW_NAMESPACE" \
  --ignore-not-found
run_command kubectl apply \
  --namespace "$WORKFLOW_NAMESPACE" \
  --filename "$HELLO_WORLD_WORKFLOW"

if [ "$DRY_RUN" != "true" ]; then
  kubectl wait pods \
    --namespace "$ARGO_WORKFLOWS_NAMESPACE" \
    --selector "app.kubernetes.io/instance=${ARGO_WORKFLOWS_RELEASE}" \
    --for=condition=Ready \
    --timeout="$HELM_WAIT_TIMEOUT"
  wait_for_resource_jsonpath \
    workflow/hello-world \
    "$WORKFLOW_NAMESPACE" \
    '{.status.phase}' \
    Succeeded \
    "Argo hello-world Workflow"

  if command -v argo >/dev/null 2>&1; then
    argo get hello-world --namespace "$WORKFLOW_NAMESPACE"
  fi

  ARGO_WORKFLOWS_SERVICE=$(kubectl get service \
    --namespace "$ARGO_WORKFLOWS_NAMESPACE" \
    --selector app.kubernetes.io/name=argo-workflows-server \
    --output jsonpath='{.items[0].metadata.name}')
fi

log "Argo Workflows workshop is ready."
if [ "${ARGO_WORKFLOWS_SERVICE:-}" ]; then
  log "UI: kubectl port-forward -n ${ARGO_WORKFLOWS_NAMESPACE} svc/${ARGO_WORKFLOWS_SERVICE} 2746:2746"
fi
