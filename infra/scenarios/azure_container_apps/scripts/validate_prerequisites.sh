#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command az
require_command curl
require_command docker
require_command jq
require_command terraform

az account show --output none >/dev/null
docker info >/dev/null

load_terraform_outputs
require_acr_outputs
az acr show \
  --name "$ACR_NAME" \
  --subscription "$AZURE_SUBSCRIPTION_ID" \
  --output none >/dev/null

log "Prerequisite validation succeeded."
log "Resource group: ${RESOURCE_GROUP_NAME}"
log "Container registry: ${ACR_NAME}"
log "Registry login server: ${ACR_LOGIN_SERVER}"
log "Image platform: ${IMAGE_PLATFORM}"
