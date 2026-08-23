#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

for command_name in az jq kubectl terraform; do
  require_command "$command_name"
done

load_cluster_outputs

AKS_JSON=$(az aks show --resource-group "$RESOURCE_GROUP_NAME" --name "$AKS_NAME" --output json)

NETWORK_PLUGIN=$(printf '%s' "$AKS_JSON" | jq -r '.networkProfile.networkPlugin // ""')
NETWORK_PLUGIN_MODE=$(printf '%s' "$AKS_JSON" | jq -r '.networkProfile.networkPluginMode // ""')
NETWORK_DATA_PLANE=$(printf '%s' "$AKS_JSON" | jq -r '.networkProfile.networkDataplane // .networkProfile.networkDataPlane // ""')
OIDC_ENABLED=$(printf '%s' "$AKS_JSON" | jq -r '.oidcIssuerProfile.enabled // false')
WORKLOAD_IDENTITY_ENABLED=$(printf '%s' "$AKS_JSON" | jq -r '.securityProfile.workloadIdentity.enabled // false')
KEY_VAULT_CSI_ENABLED=$(printf '%s' "$AKS_JSON" | jq -r '.addonProfiles.azureKeyvaultSecretsProvider.enabled // false')

[ "$NETWORK_PLUGIN" = "azure" ] || die "Expected Azure CNI, found: ${NETWORK_PLUGIN:-unset}."
[ "$NETWORK_PLUGIN_MODE" = "overlay" ] || die "Expected Azure CNI Overlay, found: ${NETWORK_PLUGIN_MODE:-unset}."
[ "$NETWORK_DATA_PLANE" = "cilium" ] || die "Expected Cilium data plane, found: ${NETWORK_DATA_PLANE:-unset}."
[ "$OIDC_ENABLED" = "true" ] || die "OIDC issuer is not enabled."
[ "$WORKLOAD_IDENTITY_ENABLED" = "true" ] || die "Workload Identity is not enabled."
[ "$KEY_VAULT_CSI_ENABLED" = "true" ] || die "Azure Key Vault Secrets Store CSI driver is not enabled."

NODES_JSON=$(kubectl get nodes -o json)
NOT_READY_COUNT=$(printf '%s' "$NODES_JSON" | jq '[.items[] | select(([.status.conditions[] | select(.type == "Ready" and .status == "True")] | length) == 0)] | length')
SYSTEM_NODE_COUNT=$(printf '%s' "$NODES_JSON" | jq '[.items[] | select(.metadata.labels["kubernetes.azure.com/mode"] == "system")] | length')
USER_NODE_COUNT=$(printf '%s' "$NODES_JSON" | jq '[.items[] | select(.metadata.labels["kubernetes.azure.com/mode"] == "user")] | length')

[ "$NOT_READY_COUNT" -eq 0 ] || die "${NOT_READY_COUNT} node(s) are not Ready."
[ "$SYSTEM_NODE_COUNT" -ge 2 ] || die "At least two system nodes are required; found ${SYSTEM_NODE_COUNT}."
[ "$USER_NODE_COUNT" -ge 1 ] || die "At least one user node is required; found ${USER_NODE_COUNT}."

USER_MEMORY_MIB=$(printf '%s' "$NODES_JSON" | jq -r '
  .items[]
  | select(.metadata.labels["kubernetes.azure.com/mode"] == "user")
  | .status.allocatable.memory
' | awk '
  /Ki$/ { total += substr($0, 1, length($0) - 2) / 1024; next }
  /Mi$/ { total += substr($0, 1, length($0) - 2); next }
  /Gi$/ { total += substr($0, 1, length($0) - 2) * 1024; next }
  END { printf "%.0f", total }
')
: "${MIN_USER_ALLOCATABLE_MEMORY_MIB:=8192}"
[ "$USER_MEMORY_MIB" -ge "$MIN_USER_ALLOCATABLE_MEMORY_MIB" ] \
  || die "User node pool has ${USER_MEMORY_MIB} MiB allocatable memory; at least ${MIN_USER_ALLOCATABLE_MEMORY_MIB} MiB is required."

DEFAULT_STORAGE_CLASS=$(kubectl get storageclass -o json | jq -r '
  .items[]
  | select(
      .metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true"
      or .metadata.annotations["storageclass.beta.kubernetes.io/is-default-class"] == "true"
    )
  | .metadata.name
' | head -n 1)
[ -n "$DEFAULT_STORAGE_CLASS" ] || die "No default StorageClass is configured."

if ! kubectl top nodes >/dev/null 2>&1; then
  warn "Metrics API is not ready. Wait a few minutes before running HPA exercises."
fi

log "Cluster validation succeeded."
log "Network: ${NETWORK_PLUGIN}/${NETWORK_PLUGIN_MODE}, data plane: ${NETWORK_DATA_PLANE}"
log "Nodes: ${SYSTEM_NODE_COUNT} system, ${USER_NODE_COUNT} user"
log "User node allocatable memory: ${USER_MEMORY_MIB} MiB"
log "Default StorageClass: ${DEFAULT_STORAGE_CLASS}"
