#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name CONTAINER_NAME "$CONTAINER_NAME"
validate_blob_name "$BLOB_NAME"
[ -f "$RESTAURANT_DATA_FILE" ] || die "Restaurant data file not found: ${RESTAURANT_DATA_FILE}"

STORAGE_TOKEN=$(get_access_token "https://storage.azure.com/.default")
ENCODED_BLOB_NAME=$(url_encode "$BLOB_NAME")
CONTAINER_URL="${BLOB_ENDPOINT}/${CONTAINER_NAME}"
BLOB_URL="${CONTAINER_URL}/${ENCODED_BLOB_NAME}"

http_request \
  --request PUT \
  "${CONTAINER_URL}?restype=container" \
  --header "Authorization: Bearer ${STORAGE_TOKEN}" \
  --header "x-ms-date: $(storage_request_date)" \
  --header "x-ms-version: ${STORAGE_API_VERSION}" \
  --header "Content-Length: 0"

case "$HTTP_STATUS" in
  201)
    log "Created private Blob container: ${CONTAINER_NAME}"
    ;;
  409)
    if grep -q '<Code>ContainerAlreadyExists</Code>' "$HTTP_BODY_FILE"; then
      log "Blob container already exists: ${CONTAINER_NAME}"
    else
      print_http_body >&2
      die "Blob container creation returned an unexpected conflict."
    fi
    ;;
  *)
    expect_http_status 201
    ;;
esac

http_request \
  --request PUT \
  "$BLOB_URL" \
  --header "Authorization: Bearer ${STORAGE_TOKEN}" \
  --header "x-ms-date: $(storage_request_date)" \
  --header "x-ms-version: ${STORAGE_API_VERSION}" \
  --header "x-ms-blob-type: BlockBlob" \
  --header "Content-Type: text/csv; charset=utf-8" \
  --data-binary "@${RESTAURANT_DATA_FILE}"

expect_http_status 201
STORAGE_TOKEN=""

log "Uploaded restaurant reviews to ${BLOB_ENDPOINT}/${CONTAINER_NAME}/${BLOB_NAME}"