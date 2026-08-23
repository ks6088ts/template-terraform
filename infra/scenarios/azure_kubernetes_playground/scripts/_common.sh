#!/bin/sh

set -eu

: "${SCRIPT_DIR:=$(CDPATH='' cd "$(dirname "$0")" && pwd)}"
SCENARIO_DIR=$(CDPATH='' cd "${SCRIPT_DIR}/.." && pwd)

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

terraform_output() {
  terraform -chdir="${SCENARIO_DIR}" output -raw "$1"
}

load_cluster_outputs() {
  RESOURCE_GROUP_NAME=$(terraform_output resource_group_name)
  AKS_NAME=$(terraform_output aks_name)
  ACR_NAME=$(terraform_output acr_name)

  [ -n "$RESOURCE_GROUP_NAME" ] || die "Terraform output resource_group_name is empty."
  [ -n "$AKS_NAME" ] || die "Terraform output aks_name is empty."
  [ -n "$ACR_NAME" ] || die "Terraform output acr_name is empty."
}
