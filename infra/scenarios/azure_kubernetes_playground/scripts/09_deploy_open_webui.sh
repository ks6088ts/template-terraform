#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${OPEN_WEBUI_NAMESPACE:=open-webui}"
: "${OPEN_WEBUI_RELEASE:=open-webui}"
: "${OPEN_WEBUI_CHART_VERSION:=16.0.0}"
OPEN_WEBUI_VALUES="${SCENARIO_DIR}/manifests/open-webui/values.yaml"

require_common_commands
require_command helm
require_command openssl
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

ensure_workshop_namespace "$OPEN_WEBUI_NAMESPACE"

if [ "$DRY_RUN" = "true" ]; then
  print_command kubectl create secret generic open-webui-secrets \
    --namespace "$OPEN_WEBUI_NAMESPACE" \
    --from-literal WEBUI_SECRET_KEY='<generated>' \
    --dry-run=client \
    --output yaml
else
  if ! kubectl get secret open-webui-secrets --namespace "$OPEN_WEBUI_NAMESPACE" >/dev/null 2>&1; then
    WEBUI_SECRET_KEY=$(openssl rand -hex 32)
    kubectl create secret generic open-webui-secrets \
      --namespace "$OPEN_WEBUI_NAMESPACE" \
      --from-literal "WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}" \
      --dry-run=client \
      --output yaml \
      | kubectl apply --filename -
    WEBUI_SECRET_KEY=""
  fi
fi

run_command helm repo add open-webui https://helm.openwebui.com/ --force-update
run_command helm repo update open-webui
helm_upgrade_install \
  "$OPEN_WEBUI_RELEASE" \
  open-webui/open-webui \
  "$OPEN_WEBUI_NAMESPACE" \
  "$OPEN_WEBUI_CHART_VERSION" \
  "$OPEN_WEBUI_VALUES"

if [ "$DRY_RUN" != "true" ]; then
  kubectl wait pods \
    --namespace "$OPEN_WEBUI_NAMESPACE" \
    --selector "app.kubernetes.io/instance=${OPEN_WEBUI_RELEASE}" \
    --for=condition=Ready \
    --timeout="$HELM_WAIT_TIMEOUT"

  OPEN_WEBUI_PVC=$(kubectl get persistentvolumeclaim \
    --namespace "$OPEN_WEBUI_NAMESPACE" \
    --output jsonpath='{.items[0].metadata.name}')
  [ -n "$OPEN_WEBUI_PVC" ] || die "Open WebUI PersistentVolumeClaim was not found."
  wait_for_resource_jsonpath \
    "persistentvolumeclaim/${OPEN_WEBUI_PVC}" \
    "$OPEN_WEBUI_NAMESPACE" \
    '{.status.phase}' \
    Bound \
    "Open WebUI storage"

  OPEN_WEBUI_SERVICE=$(kubectl get service \
    --namespace "$OPEN_WEBUI_NAMESPACE" \
    --selector app.kubernetes.io/name=open-webui \
    --output jsonpath='{.items[0].metadata.name}')
  [ -n "$OPEN_WEBUI_SERVICE" ] || die "Open WebUI Service was not found."
fi

log "Open WebUI workshop is ready."
if [ "${OPEN_WEBUI_SERVICE:-}" ]; then
  log "UI: kubectl port-forward -n ${OPEN_WEBUI_NAMESPACE} svc/${OPEN_WEBUI_SERVICE} 3000:80"
fi
log "Configure an external model provider after the first login; this workshop does not deploy a model."
