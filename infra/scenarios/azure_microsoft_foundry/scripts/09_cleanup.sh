#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

[ "${CONFIRM_CLEANUP:-}" = "delete-foundry-iq-resources" ] \
  || die "Set CONFIRM_CLEANUP=delete-foundry-iq-resources to delete the script-created resources."

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name CONTAINER_NAME "$CONTAINER_NAME"
validate_blob_name "$BLOB_NAME"
validate_resource_name KNOWLEDGE_SOURCE_NAME "$KNOWLEDGE_SOURCE_NAME"
validate_resource_name KNOWLEDGE_BASE_NAME "$KNOWLEDGE_BASE_NAME"
validate_resource_name PROJECT_CONNECTION_NAME "$PROJECT_CONNECTION_NAME"
validate_resource_name AGENT_NAME "$AGENT_NAME"

FOUNDRY_TOKEN=$(get_access_token "https://ai.azure.com/.default")
ARM_TOKEN=$(get_access_token "https://management.azure.com/.default")
SEARCH_TOKEN=$(get_access_token "https://search.azure.com/.default")
STORAGE_TOKEN=$(get_access_token "https://storage.azure.com/.default")

delete_allow_not_found() {
  DELETE_LABEL=$1
  shift
  http_request "$@"
  case "$HTTP_STATUS" in
    200|202|204)
      log "Deleted ${DELETE_LABEL}."
      ;;
    404)
      log "Already absent: ${DELETE_LABEL}."
      ;;
    *)
      print_http_body >&2
      die "Failed to delete ${DELETE_LABEL}; HTTP status ${HTTP_STATUS}."
      ;;
  esac
}

ENCODED_AGENT_NAME=$(url_encode "$AGENT_NAME")
delete_allow_not_found "Foundry agent ${AGENT_NAME}" \
  --request DELETE \
  "${PROJECT_ENDPOINT}/agents/${ENCODED_AGENT_NAME}?api-version=${AGENT_API_VERSION}" \
  --header "Authorization: Bearer ${FOUNDRY_TOKEN}" \
  --header "Accept: application/json"

ENCODED_CONNECTION_NAME=$(url_encode "$PROJECT_CONNECTION_NAME")
delete_allow_not_found "Foundry project connection ${PROJECT_CONNECTION_NAME}" \
  --request DELETE \
  "https://management.azure.com${PROJECT_ID}/connections/${ENCODED_CONNECTION_NAME}?api-version=${PROJECT_CONNECTION_API_VERSION}" \
  --header "Authorization: Bearer ${ARM_TOKEN}" \
  --header "Accept: application/json"

delete_allow_not_found "knowledge base ${KNOWLEDGE_BASE_NAME}" \
  --request DELETE \
  "${SEARCH_ENDPOINT}/knowledgebases('${KNOWLEDGE_BASE_NAME}')?api-version=${SEARCH_API_VERSION}" \
  --header "Authorization: Bearer ${SEARCH_TOKEN}" \
  --header "Accept: application/json"

delete_allow_not_found "knowledge source ${KNOWLEDGE_SOURCE_NAME}" \
  --request DELETE \
  "${SEARCH_ENDPOINT}/knowledgesources('${KNOWLEDGE_SOURCE_NAME}')?api-version=${SEARCH_API_VERSION}" \
  --header "Authorization: Bearer ${SEARCH_TOKEN}" \
  --header "Accept: application/json"

ENCODED_BLOB_NAME=$(url_encode "$BLOB_NAME")
delete_allow_not_found "Blob ${BLOB_NAME}" \
  --request DELETE \
  "${BLOB_ENDPOINT}/${CONTAINER_NAME}/${ENCODED_BLOB_NAME}" \
  --header "Authorization: Bearer ${STORAGE_TOKEN}" \
  --header "x-ms-date: $(storage_request_date)" \
  --header "x-ms-version: ${STORAGE_API_VERSION}" \
  --header "x-ms-delete-snapshots: include"

delete_allow_not_found "Blob container ${CONTAINER_NAME}" \
  --request DELETE \
  "${BLOB_ENDPOINT}/${CONTAINER_NAME}?restype=container" \
  --header "Authorization: Bearer ${STORAGE_TOKEN}" \
  --header "x-ms-date: $(storage_request_date)" \
  --header "x-ms-version: ${STORAGE_API_VERSION}"

FOUNDRY_TOKEN=""
ARM_TOKEN=""
SEARCH_TOKEN=""
STORAGE_TOKEN=""

log "Foundry IQ script-created resources were cleaned up. Terraform-managed infrastructure was not changed."