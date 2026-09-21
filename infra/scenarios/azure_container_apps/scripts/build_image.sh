#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command docker
require_command jq
require_command terraform

load_terraform_outputs
set_image_tag_reference

log "Building ${IMAGE_TAG_REFERENCE} for ${IMAGE_PLATFORM}..."
docker build \
  --platform "$IMAGE_PLATFORM" \
  --tag "$IMAGE_TAG_REFERENCE" \
  "$SOURCE_DIR"

log "Built image: ${IMAGE_TAG_REFERENCE}"
