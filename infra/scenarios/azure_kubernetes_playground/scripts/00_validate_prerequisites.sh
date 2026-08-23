#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

for command_name in az terraform kubectl helm docker jq; do
  require_command "$command_name"
done

for optional_command in kubens k9s argocd argo; do
  if ! command -v "$optional_command" >/dev/null 2>&1; then
    warn "Optional command not found: ${optional_command}. Some workshop scenarios require it."
  fi
done

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
TERRAFORM_MAJOR=$(printf '%s' "$TERRAFORM_VERSION" | cut -d. -f1)
TERRAFORM_MINOR=$(printf '%s' "$TERRAFORM_VERSION" | cut -d. -f2)
if [ "$TERRAFORM_MAJOR" -lt 1 ] || { [ "$TERRAFORM_MAJOR" -eq 1 ] && [ "$TERRAFORM_MINOR" -lt 6 ]; }; then
  die "Terraform 1.6 or later is required; found ${TERRAFORM_VERSION}."
fi

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
SUBSCRIPTION_NAME=$(az account show --query name --output tsv)
[ -n "$SUBSCRIPTION_ID" ] || die "Azure CLI is not signed in. Run: az login"

: "${LOCATION:=japaneast}"
: "${SYSTEM_VM_SIZE:=Standard_D4s_v3}"
: "${USER_VM_SIZE:=Standard_D4s_v3}"
: "${SYSTEM_NODE_COUNT:=2}"
: "${USER_NODE_MIN_COUNT:=1}"

VM_SKUS_JSON=$(az vm list-skus \
  --location "$LOCATION" \
  --resource-type virtualMachines \
  --all \
  --output json)

sku_property() {
  printf '%s' "$VM_SKUS_JSON" | jq -r --arg sku_name "$1" --arg property_name "$2" '
    [.[] | select(.name == $sku_name and (.restrictions | length) == 0)][0]
    | if . == null then empty
      elif $property_name == "vcpus" then [.capabilities[] | select(.name == "vCPUs") | .value][0]
      else .[$property_name]
      end
  '
}

SYSTEM_VCPUS=$(sku_property "$SYSTEM_VM_SIZE" vcpus)
USER_VCPUS=$(sku_property "$USER_VM_SIZE" vcpus)
SYSTEM_FAMILY=$(sku_property "$SYSTEM_VM_SIZE" family)
USER_FAMILY=$(sku_property "$USER_VM_SIZE" family)

[ -n "$SYSTEM_VCPUS" ] || die "VM SKU ${SYSTEM_VM_SIZE} is unavailable for this subscription in ${LOCATION}."
[ -n "$USER_VCPUS" ] || die "VM SKU ${USER_VM_SIZE} is unavailable for this subscription in ${LOCATION}."

REQUIRED_VCPUS=$((SYSTEM_VCPUS * SYSTEM_NODE_COUNT + USER_VCPUS * USER_NODE_MIN_COUNT))
VM_USAGE_JSON=$(az vm list-usage --location "$LOCATION" --output json)

quota_remaining() {
  printf '%s' "$VM_USAGE_JSON" | jq -r --arg quota_name "$1" '
    [.[] | select(.name.value == $quota_name)][0]
    | if . == null then empty else ((.limit | tonumber) - (.currentValue | tonumber)) end
  '
}

REGIONAL_VCPUS_REMAINING=$(quota_remaining cores)
[ -n "$REGIONAL_VCPUS_REMAINING" ] || die "Unable to read the Total Regional vCPUs quota for ${LOCATION}."
[ "$REGIONAL_VCPUS_REMAINING" -ge "$REQUIRED_VCPUS" ] \
  || die "At least ${REQUIRED_VCPUS} regional vCPUs are required; ${REGIONAL_VCPUS_REMAINING} remain in ${LOCATION}."

if [ "$SYSTEM_FAMILY" = "$USER_FAMILY" ]; then
  FAMILY_VCPUS_REMAINING=$(quota_remaining "$SYSTEM_FAMILY")
  [ -n "$FAMILY_VCPUS_REMAINING" ] || die "Unable to read the ${SYSTEM_FAMILY} quota for ${LOCATION}."
  [ "$FAMILY_VCPUS_REMAINING" -ge "$REQUIRED_VCPUS" ] \
    || die "At least ${REQUIRED_VCPUS} ${SYSTEM_FAMILY} vCPUs are required; ${FAMILY_VCPUS_REMAINING} remain."
fi

log "Prerequisite validation succeeded."
log "Terraform: ${TERRAFORM_VERSION}"
log "Azure subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})"
log "Location: ${LOCATION}"
log "System node SKU: ${SYSTEM_VM_SIZE}"
log "User node SKU: ${USER_VM_SIZE}"
log "Required initial vCPUs: ${REQUIRED_VCPUS}"
