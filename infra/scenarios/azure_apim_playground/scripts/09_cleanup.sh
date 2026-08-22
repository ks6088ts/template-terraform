#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

[ "${CONFIRM_CLEANUP:-}" = "delete-apim-playground-data" ] \
  || die "Set CONFIRM_CLEANUP=delete-apim-playground-data to delete script-created data-plane resources."

require_common_commands
load_terraform_outputs

if [ "$CONTENT_SAFETY_ENABLED" != "true" ]; then
  log "Content Safety is disabled; no script-created data-plane resources exist."
  exit 0
fi

require_value subscription_id "$AZURE_SUBSCRIPTION_ID"
require_value content_safety_endpoint "$CONTENT_SAFETY_ENDPOINT"
require_value content_safety_blocklist_name "$CONTENT_SAFETY_BLOCKLIST_NAME"

ENCODED_BLOCKLIST_NAME=$(url_encode "$CONTENT_SAFETY_BLOCKLIST_NAME")
BLOCKLIST_URL="${CONTENT_SAFETY_ENDPOINT}/contentsafety/text/blocklists/${ENCODED_BLOCKLIST_NAME}?api-version=${CONTENT_SAFETY_API_VERSION}"
CONTENT_SAFETY_TOKEN=$(get_access_token "https://cognitiveservices.azure.com/.default")

http_request \
  --request DELETE \
  "$BLOCKLIST_URL" \
  --header "Authorization: Bearer ${CONTENT_SAFETY_TOKEN}" \
  --header "Accept: application/json"
CONTENT_SAFETY_TOKEN=""

case "$HTTP_STATUS" in
  200|204)
    log "Deleted Content Safety blocklist: ${CONTENT_SAFETY_BLOCKLIST_NAME}"
    ;;
  404)
    log "Content Safety blocklist is already absent: ${CONTENT_SAFETY_BLOCKLIST_NAME}"
    ;;
  *)
    print_http_body >&2
    die "Failed to delete the Content Safety blocklist; HTTP status ${HTTP_STATUS}."
    ;;
esac

log "Terraform-managed infrastructure was not changed."
