#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${MONITORING_NAMESPACE:=monitoring}"
: "${MONITORING_RELEASE:=kube-prometheus-stack}"
: "${KUBE_PROMETHEUS_STACK_VERSION:=88.5.4}"
: "${HTTP_NAMESPACE:=workshop-http}"
MONITORING_VALUES="${SCENARIO_DIR}/manifests/monitoring/values.yaml"
HTTP_SERVICE_MONITOR="${SCENARIO_DIR}/manifests/http-server/servicemonitor.yaml"

require_common_commands
require_command helm
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

run_command helm repo add \
  prometheus-community \
  https://prometheus-community.github.io/helm-charts \
  --force-update
run_command helm repo update prometheus-community

helm_upgrade_install \
  "$MONITORING_RELEASE" \
  prometheus-community/kube-prometheus-stack \
  "$MONITORING_NAMESPACE" \
  "$KUBE_PROMETHEUS_STACK_VERSION" \
  "$MONITORING_VALUES"

if [ "$DRY_RUN" != "true" ]; then
  kubectl wait pods \
    --namespace "$MONITORING_NAMESPACE" \
    --selector "app.kubernetes.io/instance=${MONITORING_RELEASE}" \
    --for=condition=Ready \
    --timeout="$HELM_WAIT_TIMEOUT"

  if kubectl get namespace "$HTTP_NAMESPACE" >/dev/null 2>&1; then
    kubectl apply \
      --namespace "$HTTP_NAMESPACE" \
      --filename "$HTTP_SERVICE_MONITOR"
    kubectl get servicemonitor http-server \
      --namespace "$HTTP_NAMESPACE" \
      >/dev/null
  else
    log "HTTP workshop namespace is absent; cluster monitoring is ready without the application target."
  fi

  GRAFANA_SERVICE=$(kubectl get service \
    --namespace "$MONITORING_NAMESPACE" \
    --selector app.kubernetes.io/name=grafana \
    --output jsonpath='{.items[0].metadata.name}')
  PROMETHEUS_SERVICE=$(kubectl get service \
    --namespace "$MONITORING_NAMESPACE" \
    --selector app.kubernetes.io/name=prometheus \
    --output jsonpath='{.items[0].metadata.name}')
  [ -n "$GRAFANA_SERVICE" ] || die "Grafana Service was not found."
  [ -n "$PROMETHEUS_SERVICE" ] || die "Prometheus Service was not found."
fi

log "Monitoring workshop is ready."
if [ "${GRAFANA_SERVICE:-}" ]; then
  log "Grafana: kubectl port-forward -n ${MONITORING_NAMESPACE} svc/${GRAFANA_SERVICE} 3000:80"
  log "Prometheus: kubectl port-forward -n ${MONITORING_NAMESPACE} svc/${PROMETHEUS_SERVICE} 9090:9090"
fi
