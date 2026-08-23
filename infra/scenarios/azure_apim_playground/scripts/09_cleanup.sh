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
BLOCKLIST_ITEMS_URL="${CONTENT_SAFETY_ENDPOINT}/contentsafety/text/blocklists/${ENCODED_BLOCKLIST_NAME}/blocklistItems?api-version=${CONTENT_SAFETY_API_VERSION}"
REMOVE_BLOCKLIST_ITEMS_URL="${CONTENT_SAFETY_ENDPOINT}/contentsafety/text/blocklists/${ENCODED_BLOCKLIST_NAME}:removeBlocklistItems?api-version=${CONTENT_SAFETY_API_VERSION}"
CONTENT_SAFETY_TOKEN=$(get_access_token "https://cognitiveservices.azure.com/.default")

http_request \
  --request GET \
  "$BLOCKLIST_ITEMS_URL" \
  --header "Authorization: Bearer ${CONTENT_SAFETY_TOKEN}" \
  --header "Accept: application/json"

case "$HTTP_STATUS" in
  200)
    BLOCKLIST_ITEM_IDS=$(jq -c --arg blocked_text "$CONTENT_SAFETY_BLOCKED_TEXT" '
      [(.value // .values // [])[]
        | select(.text == $blocked_text)
        | .blocklistItemId]
    ' "$HTTP_BODY_FILE")
    BLOCKLIST_ITEM_COUNT=$(printf '%s' "$BLOCKLIST_ITEM_IDS" | jq -r 'length')

    if [ "$BLOCKLIST_ITEM_COUNT" -eq 0 ]; then
      log "Content Safety test blocklist item is already absent: ${CONTENT_SAFETY_BLOCKLIST_NAME}"
    else
      REMOVE_PAYLOAD=$(jq -n \
        --argjson blocklist_item_ids "$BLOCKLIST_ITEM_IDS" \
        '{blocklistItemIds: $blocklist_item_ids}')
      http_request \
        --request POST \
        "$REMOVE_BLOCKLIST_ITEMS_URL" \
        --header "Authorization: Bearer ${CONTENT_SAFETY_TOKEN}" \
        --header "Content-Type: application/json" \
        --header "Accept: application/json" \
        --data "$REMOVE_PAYLOAD"
      expect_http_status 200 204
      log "Removed ${BLOCKLIST_ITEM_COUNT} Content Safety test blocklist item(s): ${CONTENT_SAFETY_BLOCKLIST_NAME}"
    fi
    ;;
  404)
    log "Content Safety blocklist is absent; no test items to remove: ${CONTENT_SAFETY_BLOCKLIST_NAME}"
    ;;
  *)
    print_http_body >&2
    die "Failed to list Content Safety blocklist items; HTTP status ${HTTP_STATUS}."
    ;;
esac
CONTENT_SAFETY_TOKEN=""

log "Content Safety blocklist container was retained to preserve the API Management policy reference."
log "Terraform-managed infrastructure was not changed."
