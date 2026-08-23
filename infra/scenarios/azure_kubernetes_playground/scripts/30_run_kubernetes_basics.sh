#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command kubectl

EXAMPLE_DIR="${SCENARIO_DIR}/examples/kubernetes_basics"
NAMESPACE="workshop-basics"

kubectl apply -k "$EXAMPLE_DIR"
kubectl rollout status deployment/web --namespace "$NAMESPACE" --timeout=5m
kubectl rollout status statefulset/data-writer --namespace "$NAMESPACE" --timeout=5m
kubectl rollout status daemonset/node-observer --namespace "$NAMESPACE" --timeout=5m
kubectl wait --for=condition=complete job/one-time-task --namespace "$NAMESPACE" --timeout=5m

PVC_PHASE=$(kubectl get pvc data-data-writer-0 --namespace "$NAMESPACE" --output jsonpath='{.status.phase}')
[ "$PVC_PHASE" = "Bound" ] || die "Expected PVC data-data-writer-0 to be Bound, found: ${PVC_PHASE}."

CAN_READ_CONFIGMAPS=$(kubectl auth can-i get configmaps \
  --as "system:serviceaccount:${NAMESPACE}:workshop-reader" \
  --namespace "$NAMESPACE")
[ "$CAN_READ_CONFIGMAPS" = "yes" ] || die "The workshop-reader ServiceAccount cannot read ConfigMaps."

kubectl get all,pvc,configmap,secret,networkpolicy,poddisruptionbudget \
  --namespace "$NAMESPACE"

log "Kubernetes basics validation succeeded."
log "Run 'kubectl port-forward -n ${NAMESPACE} service/web 8080:80' to open the sample service."
log "Run 'kubectl delete -k ${EXAMPLE_DIR}' when the exercise is complete."
