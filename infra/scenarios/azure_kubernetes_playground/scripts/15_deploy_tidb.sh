#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${TIDB_OPERATOR_NAMESPACE:=tidb-admin}"
: "${TIDB_OPERATOR_RELEASE:=tidb-operator}"
: "${TIDB_OPERATOR_VERSION:=v1.6.6}"
: "${TIDB_CLUSTER_NAMESPACE:=tidb-cluster}"
: "${TIDB_CLUSTER_NAME:=basic}"
TIDB_OPERATOR_VALUES="${SCENARIO_DIR}/manifests/tidb/operator-values.yaml"
TIDB_CLUSTER_MANIFEST="${SCENARIO_DIR}/manifests/tidb/tidb-cluster.yaml"
TIDB_CRD_URL="https://raw.githubusercontent.com/pingcap/tidb-operator/${TIDB_OPERATOR_VERSION}/manifests/crd.yaml"

require_common_commands
require_command helm
validate_configuration
load_terraform_outputs
require_scenario_outputs

[ "${CONFIRM_STATEFUL_WORKLOAD:-}" = "deploy-tidb-test-cluster" ] \
  || die "Set CONFIRM_STATEFUL_WORKLOAD=deploy-tidb-test-cluster to deploy the TiDB test cluster."

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

run_command kubectl apply --filename "$TIDB_CRD_URL"
if [ "$DRY_RUN" != "true" ]; then
  kubectl wait \
    --for=condition=Established \
    crd/tidbclusters.pingcap.com \
    --timeout="$KUBECTL_WAIT_TIMEOUT"
fi

run_command helm repo add pingcap https://charts.pingcap.com/ --force-update
run_command helm repo update pingcap
helm_upgrade_install \
  "$TIDB_OPERATOR_RELEASE" \
  pingcap/tidb-operator \
  "$TIDB_OPERATOR_NAMESPACE" \
  "$TIDB_OPERATOR_VERSION" \
  "$TIDB_OPERATOR_VALUES"

ensure_workshop_namespace "$TIDB_CLUSTER_NAMESPACE"
run_command kubectl apply \
  --namespace "$TIDB_CLUSTER_NAMESPACE" \
  --filename "$TIDB_CLUSTER_MANIFEST"

if [ "$DRY_RUN" != "true" ]; then
  for component_name in pd tikv tidb; do
    wait_for_resource_jsonpath \
      "statefulset/${TIDB_CLUSTER_NAME}-${component_name}" \
      "$TIDB_CLUSTER_NAMESPACE" \
      '{.metadata.name}' \
      "${TIDB_CLUSTER_NAME}-${component_name}" \
      "TiDB ${component_name} StatefulSet creation"
    kubectl rollout status \
      "statefulset/${TIDB_CLUSTER_NAME}-${component_name}" \
      --namespace "$TIDB_CLUSTER_NAMESPACE" \
      --timeout="$HELM_WAIT_TIMEOUT"
  done

  UNBOUND_PVC_COUNT=$(kubectl get persistentvolumeclaim \
    --namespace "$TIDB_CLUSTER_NAMESPACE" \
    --output json \
    | jq '[.items[] | select(.status.phase != "Bound")] | length')
  [ "$UNBOUND_PVC_COUNT" -eq 0 ] \
    || die "TiDB has ${UNBOUND_PVC_COUNT} unbound PersistentVolumeClaims."
  kubectl get service "${TIDB_CLUSTER_NAME}-tidb" \
    --namespace "$TIDB_CLUSTER_NAMESPACE" \
    >/dev/null
fi

log "TiDB workshop is ready."
log "Connect: kubectl port-forward -n ${TIDB_CLUSTER_NAMESPACE} svc/${TIDB_CLUSTER_NAME}-tidb 14000:4000"
log "Then run: mysql --comments -h 127.0.0.1 -P 14000 -u root"
log "PersistentVolumes use the Retain policy and are not deleted with the TiDB cluster."
