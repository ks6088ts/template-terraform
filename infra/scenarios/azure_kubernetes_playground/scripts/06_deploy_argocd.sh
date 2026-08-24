#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${ARGOCD_NAMESPACE:=argocd}"
: "${ARGOCD_RELEASE:=argocd}"
: "${ARGOCD_CHART_VERSION:=10.4.0}"
: "${GUESTBOOK_NAMESPACE:=workshop-guestbook}"
ARGOCD_VALUES="${SCENARIO_DIR}/manifests/argocd/values.yaml"
GUESTBOOK_APPLICATION="${SCENARIO_DIR}/manifests/argocd/guestbook-application.yaml"

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
  "$ARGOCD_RELEASE" \
  argo/argo-cd \
  "$ARGOCD_NAMESPACE" \
  "$ARGOCD_CHART_VERSION" \
  "$ARGOCD_VALUES"

ensure_workshop_namespace "$GUESTBOOK_NAMESPACE"
run_command kubectl apply --filename "$GUESTBOOK_APPLICATION"

if [ "$DRY_RUN" != "true" ]; then
  kubectl wait pods \
    --namespace "$ARGOCD_NAMESPACE" \
    --selector "app.kubernetes.io/instance=${ARGOCD_RELEASE}" \
    --for=condition=Ready \
    --timeout="$HELM_WAIT_TIMEOUT"
  wait_for_resource_jsonpath \
    application/guestbook \
    "$ARGOCD_NAMESPACE" \
    '{.status.sync.status}' \
    Synced \
    "Argo CD guestbook sync"
  wait_for_resource_jsonpath \
    application/guestbook \
    "$ARGOCD_NAMESPACE" \
    '{.status.health.status}' \
    Healthy \
    "Argo CD guestbook health"
  kubectl get secret argocd-initial-admin-secret \
    --namespace "$ARGOCD_NAMESPACE" \
    >/dev/null

  ARGOCD_SERVICE=$(kubectl get service \
    --namespace "$ARGOCD_NAMESPACE" \
    --selector app.kubernetes.io/name=argocd-server \
    --output jsonpath='{.items[0].metadata.name}')
fi

log "Argo CD workshop is ready."
if [ "${ARGOCD_SERVICE:-}" ]; then
  log "UI: kubectl port-forward -n ${ARGOCD_NAMESPACE} svc/${ARGOCD_SERVICE} 8080:443"
  log "Retrieve the generated admin password from Secret argocd-initial-admin-secret, then change it and delete the Secret."
fi
