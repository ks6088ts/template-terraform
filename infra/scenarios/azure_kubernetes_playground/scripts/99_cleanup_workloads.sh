#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command kubectl

WORKSHOP_NAMESPACES="workshop-basics playground-otel develop ingress-nginx monitoring grafana argocd argo-cd argo-workflows guestbook iam genai dify kubecost otel cert-manager tidb-admin tidb-cluster"

if [ "${1:-}" != "--yes" ]; then
  log "Dry run only. The following workshop namespaces would be deleted:"
  for namespace_name in $WORKSHOP_NAMESPACES; do
    if kubectl get namespace "$namespace_name" >/dev/null 2>&1; then
      log "- ${namespace_name}"
    fi
  done
  log "Re-run with --yes to delete them. Terraform-managed Azure resources are not affected."
  exit 0
fi

for namespace_name in $WORKSHOP_NAMESPACES; do
  if kubectl get namespace "$namespace_name" >/dev/null 2>&1; then
    kubectl delete namespace "$namespace_name" --wait=false
  fi
done

warn "Cluster-scoped CRDs and resources installed by Helm charts might remain. Prefer Helm uninstall before this script, or destroy the disposable cluster after the workshop."
