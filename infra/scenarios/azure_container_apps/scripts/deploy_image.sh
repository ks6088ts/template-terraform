#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command az
require_command jq
require_command terraform

load_terraform_outputs
set_image_tag_reference

IMAGE_DIGEST=$(az acr repository show \
  --name "$ACR_NAME" \
  --subscription "$AZURE_SUBSCRIPTION_ID" \
  --image "${IMAGE_REPOSITORY}:${IMAGE_TAG}" \
  --query digest \
  --output tsv)

case "$IMAGE_DIGEST" in
  sha256:*) DIGEST_HEX=${IMAGE_DIGEST#sha256:} ;;
  *) die "ACR returned an invalid digest for ${IMAGE_REPOSITORY}:${IMAGE_TAG}: ${IMAGE_DIGEST}" ;;
esac

case "$DIGEST_HEX" in
  ''|*[!0-9a-fA-F]*) die "ACR returned an invalid SHA-256 digest: ${IMAGE_DIGEST}" ;;
esac
[ "${#DIGEST_HEX}" -eq 64 ] || die "ACR returned an invalid SHA-256 digest: ${IMAGE_DIGEST}"

IMAGE_DIGEST_REFERENCE="${ACR_LOGIN_SERVER}/${IMAGE_REPOSITORY}@${IMAGE_DIGEST}"
TEMP_VARS_FILE=$(mktemp "${DEPLOYMENT_VARS_FILE}.XXXXXX")

cleanup() {
  if [ -n "${TEMP_VARS_FILE:-}" ] && [ -f "$TEMP_VARS_FILE" ]; then
    rm -f "$TEMP_VARS_FILE"
  fi
}

trap 'cleanup' 0
trap 'cleanup; exit 1' HUP INT TERM

jq -n \
  --arg container_image "$IMAGE_DIGEST_REFERENCE" \
  '{
    container_image: $container_image,
    container_port: 8080,
    min_replicas: 1,
    max_replicas: 1
  }' >"$TEMP_VARS_FILE"

mv "$TEMP_VARS_FILE" "$DEPLOYMENT_VARS_FILE"
TEMP_VARS_FILE=""

log "Deploying immutable image: ${IMAGE_DIGEST_REFERENCE}"
terraform -chdir="$SCENARIO_DIR" apply "$@"

log "Deployment variables saved to ${DEPLOYMENT_VARS_FILE}"
