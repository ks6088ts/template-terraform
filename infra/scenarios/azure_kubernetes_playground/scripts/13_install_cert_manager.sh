#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${CERT_MANAGER_NAMESPACE:=cert-manager}"
: "${CERT_MANAGER_RELEASE:=cert-manager}"
: "${CERT_MANAGER_CHART_VERSION:=v1.21.1}"
: "${TLS_NAMESPACE:=workshop-tls}"
: "${TLS_GATEWAY_NAME:=tls-workshop}"
CERT_MANAGER_VALUES="${SCENARIO_DIR}/manifests/cert-manager/values.yaml"
TLS_MANIFEST_DIR="${SCENARIO_DIR}/manifests/cert-manager"

require_common_commands
require_command helm
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
  kubectl get "gatewayclass/${GATEWAY_CLASS_NAME}" >/dev/null
fi

helm_upgrade_install \
  "$CERT_MANAGER_RELEASE" \
  oci://quay.io/jetstack/charts/cert-manager \
  "$CERT_MANAGER_NAMESPACE" \
  "$CERT_MANAGER_CHART_VERSION" \
  "$CERT_MANAGER_VALUES"

ensure_workshop_namespace "$TLS_NAMESPACE"
run_command kubectl apply \
  --namespace "$TLS_NAMESPACE" \
  --filename "${TLS_MANIFEST_DIR}/sample-app.yaml"
run_command kubectl apply \
  --namespace "$TLS_NAMESPACE" \
  --filename "${TLS_MANIFEST_DIR}/http-gateway.yaml"

if [ "$DRY_RUN" != "true" ]; then
  for deployment_name in cert-manager cert-manager-cainjector cert-manager-webhook; do
    kubectl rollout status "deployment/${deployment_name}" \
      --namespace "$CERT_MANAGER_NAMESPACE" \
      --timeout="$HELM_WAIT_TIMEOUT"
  done
  kubectl rollout status deployment/tls-sample \
    --namespace "$TLS_NAMESPACE" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"
  kubectl wait \
    --for=condition=Programmed \
    "gateway/${TLS_GATEWAY_NAME}" \
    --namespace "$TLS_NAMESPACE" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"

  TLS_GATEWAY_ADDRESS=$(kubectl get gateway "$TLS_GATEWAY_NAME" \
    --namespace "$TLS_NAMESPACE" \
    --output jsonpath='{.status.addresses[0].value}')
  [ -n "$TLS_GATEWAY_ADDRESS" ] || die "The TLS Gateway does not have an address."
fi

log "cert-manager and the HTTP challenge Gateway are ready."
if [ "${TLS_GATEWAY_ADDRESS:-}" ]; then
  log "Create an A record for your test hostname pointing to: ${TLS_GATEWAY_ADDRESS}"
fi
log "After DNS propagates, set ACME_EMAIL and DNS_NAME and run 14_issue_certificate.sh."
