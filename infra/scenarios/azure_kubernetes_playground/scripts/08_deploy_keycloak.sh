#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${KEYCLOAK_NAMESPACE:=keycloak}"
: "${KEYCLOAK_OPERATOR_VERSION:=26.7.2}"
: "${KEYCLOAK_NAME:=workshop-keycloak}"
KEYCLOAK_MANIFEST_DIR="${SCENARIO_DIR}/manifests/keycloak"
KEYCLOAK_OPERATOR_SOURCE="github.com/keycloak/keycloak-k8s-resources/kubernetes?ref=${KEYCLOAK_OPERATOR_VERSION}"

require_common_commands
require_command openssl
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

ensure_workshop_namespace "$KEYCLOAK_NAMESPACE"
run_command kubectl apply --kustomize "$KEYCLOAK_OPERATOR_SOURCE"

if [ "$DRY_RUN" = "true" ]; then
  print_command kubectl create secret generic keycloak-db-secret \
    --namespace "$KEYCLOAK_NAMESPACE" \
    --from-literal username=keycloak \
    --from-literal password='<generated>' \
    --dry-run=client \
    --output yaml
else
  kubectl rollout status deployment/keycloak-operator \
    --namespace "$KEYCLOAK_NAMESPACE" \
    --timeout="$HELM_WAIT_TIMEOUT"

  if ! kubectl get secret keycloak-db-secret --namespace "$KEYCLOAK_NAMESPACE" >/dev/null 2>&1; then
    KEYCLOAK_DB_PASSWORD=$(openssl rand -hex 24)
    kubectl create secret generic keycloak-db-secret \
      --namespace "$KEYCLOAK_NAMESPACE" \
      --from-literal username=keycloak \
      --from-literal "password=${KEYCLOAK_DB_PASSWORD}" \
      --dry-run=client \
      --output yaml \
      | kubectl apply --filename -
    KEYCLOAK_DB_PASSWORD=""
  fi
fi

run_command kubectl apply \
  --namespace "$KEYCLOAK_NAMESPACE" \
  --filename "${KEYCLOAK_MANIFEST_DIR}/postgres.yaml"
run_command kubectl apply \
  --namespace "$KEYCLOAK_NAMESPACE" \
  --filename "${KEYCLOAK_MANIFEST_DIR}/keycloak.yaml"

if [ "$DRY_RUN" != "true" ]; then
  kubectl rollout status statefulset/postgresql-db \
    --namespace "$KEYCLOAK_NAMESPACE" \
    --timeout="$HELM_WAIT_TIMEOUT"
  wait_for_resource_jsonpath \
    "keycloak/${KEYCLOAK_NAME}" \
    "$KEYCLOAK_NAMESPACE" \
    '{.status.conditions[?(@.type=="Ready")].status}' \
    true \
    "Keycloak readiness"
fi

run_command kubectl apply \
  --namespace "$KEYCLOAK_NAMESPACE" \
  --filename "${KEYCLOAK_MANIFEST_DIR}/realm-import.yaml"

if [ "$DRY_RUN" != "true" ]; then
  wait_for_resource_jsonpath \
    keycloakrealmimport/workshop-realm \
    "$KEYCLOAK_NAMESPACE" \
    '{.status.conditions[?(@.type=="Done")].status}' \
    true \
    "Keycloak realm import"
  kubectl get secret "${KEYCLOAK_NAME}-initial-admin" \
    --namespace "$KEYCLOAK_NAMESPACE" \
    >/dev/null
fi

log "Keycloak workshop is ready."
log "UI: kubectl port-forward -n ${KEYCLOAK_NAMESPACE} svc/${KEYCLOAK_NAME}-service 8080:8080"
log "Retrieve the generated administrator username and password from Secret ${KEYCLOAK_NAME}-initial-admin."
