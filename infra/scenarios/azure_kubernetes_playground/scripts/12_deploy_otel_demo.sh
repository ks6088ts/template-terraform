#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${OTEL_DEMO_NAMESPACE:=otel-demo}"
: "${OTEL_DEMO_RELEASE:=otel-demo}"
: "${OTEL_DEMO_CHART_VERSION:=0.41.0}"
: "${MINIMUM_HELM_VERSION:=4.0.0}"
: "${MINIMUM_OTEL_DEMO_MEMORY_MIB:=6144}"
OTEL_DEMO_VALUES="${SCENARIO_DIR}/manifests/otel-demo/values.yaml"

require_common_commands
require_command helm
validate_configuration
validate_positive_integer MINIMUM_OTEL_DEMO_MEMORY_MIB "$MINIMUM_OTEL_DEMO_MEMORY_MIB"
load_terraform_outputs
require_scenario_outputs

HELM_VERSION=$(helm version --template '{{.Version}}')
version_at_least "${HELM_VERSION#v}" "$MINIMUM_HELM_VERSION" \
  || die "OpenTelemetry Demo requires Helm ${MINIMUM_HELM_VERSION} or later; found ${HELM_VERSION}."

[ "${CONFIRM_RESOURCE_INTENSIVE:-}" = "deploy-full-otel-demo" ] \
  || die "Set CONFIRM_RESOURCE_INTENSIVE=deploy-full-otel-demo to deploy the full OpenTelemetry Demo."

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context

  ALLOCATABLE_MEMORY_MIB=$(kubectl get nodes --output json | jq '[
    .items[].status.allocatable.memory
    | sub("Ki$"; "")
    | tonumber
  ] | add / 1024 | floor')
  [ "$ALLOCATABLE_MEMORY_MIB" -ge "$MINIMUM_OTEL_DEMO_MEMORY_MIB" ] \
    || die "The cluster has ${ALLOCATABLE_MEMORY_MIB} MiB allocatable memory; the Demo requires at least ${MINIMUM_OTEL_DEMO_MEMORY_MIB} MiB free."
fi

run_command helm repo add \
  open-telemetry \
  https://open-telemetry.github.io/opentelemetry-helm-charts \
  --force-update
run_command helm repo update open-telemetry
helm_upgrade_install \
  "$OTEL_DEMO_RELEASE" \
  open-telemetry/opentelemetry-demo \
  "$OTEL_DEMO_NAMESPACE" \
  "$OTEL_DEMO_CHART_VERSION" \
  "$OTEL_DEMO_VALUES"

if [ "$DRY_RUN" != "true" ]; then
  OTEL_DEMO_FRONTEND_SERVICE=$(kubectl get service \
    --namespace "$OTEL_DEMO_NAMESPACE" \
    --output json \
    | jq -r '[
      .items[]
      | select(.metadata.name | test("frontend.?proxy"; "i"))
      | .metadata.name
    ][0] // empty')
  [ -n "$OTEL_DEMO_FRONTEND_SERVICE" ] \
    || die "OpenTelemetry Demo frontend proxy Service was not found."

  kubectl get --raw \
    "/api/v1/namespaces/${OTEL_DEMO_NAMESPACE}/services/http:${OTEL_DEMO_FRONTEND_SERVICE}:8080/proxy/" \
    >/dev/null
fi

log "Full OpenTelemetry Demo is ready."
if [ "${OTEL_DEMO_FRONTEND_SERVICE:-}" ]; then
  log "UI: kubectl port-forward -n ${OTEL_DEMO_NAMESPACE} svc/${OTEL_DEMO_FRONTEND_SERVICE} 8080:8080"
  log "Web store: http://localhost:8080/"
  log "Grafana: http://localhost:8080/grafana/"
  log "Jaeger: http://localhost:8080/jaeger/ui/"
fi
