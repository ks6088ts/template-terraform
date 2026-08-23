#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command az
require_command kubectl
require_command terraform
load_cluster_outputs

az aks get-credentials \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "$AKS_NAME" \
  --overwrite-existing \
  --output none

kubectl cluster-info
kubectl get nodes -o wide
