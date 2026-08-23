#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${OTEL_NAMESPACE:=playground-otel}"
OTEL_EXAMPLE_DIR="${SCENARIO_DIR}/examples/otel_k8s"

require_common_commands
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/namespace.yaml"
ensure_workshop_namespace "$OTEL_NAMESPACE"
run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/configmap-otel-collector.yaml"
run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/configmap-prometheus.yaml"
run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/jaeger.yaml"
run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/prometheus.yaml"
run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/otel-collector.yaml"
run_command kubectl delete job telemetrygen-traces telemetrygen-metrics \
  --namespace "$OTEL_NAMESPACE" \
  --ignore-not-found
run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/job-telemetrygen-traces.yaml"
run_command kubectl apply --filename "${OTEL_EXAMPLE_DIR}/job-telemetrygen-metrics.yaml"

if [ "$DRY_RUN" != "true" ]; then
  for deployment_name in jaeger prometheus otel-collector; do
    kubectl rollout status "deployment/${deployment_name}" \
      --namespace "$OTEL_NAMESPACE" \
      --timeout="$KUBECTL_WAIT_TIMEOUT"
  done
  kubectl wait \
    --for=condition=Complete \
    job/telemetrygen-traces \
    job/telemetrygen-metrics \
    --namespace "$OTEL_NAMESPACE" \
    --timeout="$HELM_WAIT_TIMEOUT"

  JAEGER_RESPONSE=$(kubectl get --raw \
    "/api/v1/namespaces/${OTEL_NAMESPACE}/services/http:jaeger:16686/proxy/api/services")
  printf '%s' "$JAEGER_RESPONSE" | jq -e '.data | length > 0' >/dev/null \
    || die "Jaeger did not return any traced services."

  PROMETHEUS_RESPONSE=$(kubectl get --raw \
    "/api/v1/namespaces/${OTEL_NAMESPACE}/services/http:prometheus:9090/proxy/api/v1/query?query=up")
  printf '%s' "$PROMETHEUS_RESPONSE" \
    | jq -e '.status == "success" and (.data.result | length > 0)' \
    >/dev/null \
    || die "Prometheus did not return the up metric."
fi

log "Lightweight OpenTelemetry workshop is ready."
log "Jaeger: kubectl port-forward -n ${OTEL_NAMESPACE} svc/jaeger 16686:16686"
log "Prometheus: kubectl port-forward -n ${OTEL_NAMESPACE} svc/prometheus 9090:9090"
