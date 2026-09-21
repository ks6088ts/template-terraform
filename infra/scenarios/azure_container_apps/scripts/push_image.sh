#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command az
require_command docker
require_command jq
require_command terraform

load_terraform_outputs
set_image_tag_reference

docker image inspect "$IMAGE_TAG_REFERENCE" >/dev/null 2>&1 \
  || die "Local image not found: ${IMAGE_TAG_REFERENCE}. Run build_image.sh first."

log "Signing in to ${ACR_LOGIN_SERVER}..."
az acr login \
  --name "$ACR_NAME" \
  --subscription "$AZURE_SUBSCRIPTION_ID" \
  --output none

log "Pushing ${IMAGE_TAG_REFERENCE}..."
docker push "$IMAGE_TAG_REFERENCE"

log "Pushed image: ${IMAGE_TAG_REFERENCE}"
