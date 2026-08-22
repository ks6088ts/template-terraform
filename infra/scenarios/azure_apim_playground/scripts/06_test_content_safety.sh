#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_core_outputs
require_feature content_safety "$CONTENT_SAFETY_ENABLED"
require_feature ai_backend "$AI_BACKEND_ENABLED"
require_value content_safety_endpoint "$CONTENT_SAFETY_ENDPOINT"
require_value content_safety_blocklist_name "$CONTENT_SAFETY_BLOCKLIST_NAME"
require_value ai_gateway_url "$AI_GATEWAY_URL"
require_value ai_deployment_name "$AI_DEPLOYMENT_NAME"
validate_positive_integer CONTENT_SAFETY_PROPAGATION_SECONDS "$CONTENT_SAFETY_PROPAGATION_SECONDS"

ENCODED_BLOCKLIST_NAME=$(url_encode "$CONTENT_SAFETY_BLOCKLIST_NAME")
BLOCKLIST_URL="${CONTENT_SAFETY_ENDPOINT}/contentsafety/text/blocklists/${ENCODED_BLOCKLIST_NAME}?api-version=${CONTENT_SAFETY_API_VERSION}"
BLOCKLIST_ITEMS_URL="${CONTENT_SAFETY_ENDPOINT}/contentsafety/text/blocklists/${ENCODED_BLOCKLIST_NAME}:addOrUpdateBlocklistItems?api-version=${CONTENT_SAFETY_API_VERSION}"
CONTENT_SAFETY_TOKEN=$(get_access_token "https://cognitiveservices.azure.com/.default")

CREATE_PAYLOAD=$(jq -n '{description: "Terms used by the API Management playground integration test"}')
http_request \
  --request PATCH \
  "$BLOCKLIST_URL" \
  --header "Authorization: Bearer ${CONTENT_SAFETY_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$CREATE_PAYLOAD"
expect_http_status 200 201
log "Content Safety blocklist is ready: ${CONTENT_SAFETY_BLOCKLIST_NAME}"

ITEM_PAYLOAD=$(jq -n \
  --arg blocked_text "$CONTENT_SAFETY_BLOCKED_TEXT" \
  '{
    blocklistItems: [
      {
        description: "APIM playground deterministic blocked term",
        text: $blocked_text
      }
    ]
  }')
http_request \
  --request POST \
  "$BLOCKLIST_ITEMS_URL" \
  --header "Authorization: Bearer ${CONTENT_SAFETY_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$ITEM_PAYLOAD"
expect_http_status 200
BLOCKLIST_ITEM_ID=$(jq -r '.value[0].blocklistItemId // empty' "$HTTP_BODY_FILE")
CONTENT_SAFETY_TOKEN=""

sleep "$CONTENT_SAFETY_PROPAGATION_SECONDS"

AI_PAYLOAD=$(jq -n \
  --arg model "$AI_DEPLOYMENT_NAME" \
  --arg blocked_text "$CONTENT_SAFETY_BLOCKED_TEXT" \
  --arg reasoning_effort "$AI_REASONING_EFFORT" \
  '{
    model: $model,
    messages: [
      {
        role: "user",
        content: ("Repeat this exact term: " + $blocked_text)
      }
    ],
    max_completion_tokens: 8,
    stream: false
  } + (if $reasoning_effort == "" then {} else {reasoning_effort: $reasoning_effort} end)')
http_request \
  --request POST \
  "${AI_GATEWAY_URL}/chat/completions" \
  --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$AI_PAYLOAD"
expect_http_status 403

log "Content Safety blocked the configured term with HTTP 403."
if [ -n "$BLOCKLIST_ITEM_ID" ]; then
  log "Blocklist item ID: ${BLOCKLIST_ITEM_ID}"
fi

SAFE_AI_PAYLOAD=$(jq -n \
  --arg model "$AI_DEPLOYMENT_NAME" \
  --arg reasoning_effort "$AI_REASONING_EFFORT" \
  '{
    model: $model,
    messages: [
      {
        role: "user",
        content: "Reply with exactly: APIM content safety verified"
      }
    ],
    max_completion_tokens: 64,
    stream: false
  } + (if $reasoning_effort == "" then {} else {reasoning_effort: $reasoning_effort} end)')
http_request \
  --request POST \
  "${AI_GATEWAY_URL}/chat/completions" \
  --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$SAFE_AI_PAYLOAD"
expect_http_status 200

jq -e '
  .choices
  | type == "array" and any(.[]; (.message.content // "") | length > 0)
' "$HTTP_BODY_FILE" >/dev/null || die "Content Safety safe control response did not contain completion text."

log "Content Safety allowed the safe control prompt with HTTP 200."
