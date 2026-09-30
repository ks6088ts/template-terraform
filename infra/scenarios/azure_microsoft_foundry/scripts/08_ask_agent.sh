#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

parse_question_options \
  "Which fictional restaurant is a strong choice for a vegan dinner, and why?" \
  "$@"
verbose_log "Preparing a conversation and grounded prompt-agent request."

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name AGENT_NAME "$AGENT_NAME"
validate_boolean KEEP_CONVERSATION "$KEEP_CONVERSATION"

FOUNDRY_TOKEN=$(get_access_token "https://ai.azure.com/.default")
CONVERSATION_URL="${PROJECT_ENDPOINT}/openai/v1/conversations"
RESPONSES_URL="${PROJECT_ENDPOINT}/openai/v1/responses"

http_request \
  --request POST \
  "$CONVERSATION_URL" \
  --header "Authorization: Bearer ${FOUNDRY_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data '{}'

expect_http_status 200 201
CONVERSATION_ID=$(jq -r '.id // empty' "$HTTP_BODY_FILE")
[ -n "$CONVERSATION_ID" ] || die "Conversation response did not contain an ID."
log "Created conversation: ${CONVERSATION_ID}"

delete_conversation_if_needed() {
  if [ "$KEEP_CONVERSATION" = "true" ]; then
    log "Retained conversation ${CONVERSATION_ID}; pass CONVERSATION_ID to 09_cleanup.sh to remove it."
    return 0
  fi

  ENCODED_CONVERSATION_ID=$(url_encode "$CONVERSATION_ID")
  http_request \
    --request DELETE \
    "${PROJECT_ENDPOINT}/openai/v1/conversations/${ENCODED_CONVERSATION_ID}" \
    --header "Authorization: Bearer ${FOUNDRY_TOKEN}" \
    --header "Accept: application/json"
  expect_http_status 200 202 204 404
  log "Deleted transient conversation: ${CONVERSATION_ID}"
}

PAYLOAD=$(jq -n \
  --arg conversation_id "$CONVERSATION_ID" \
  --arg question "$QUESTION" \
  --arg agent_name "$AGENT_NAME" \
  '{
    conversation: $conversation_id,
    input: $question,
    tool_choice: "required",
    agent_reference: {
      type: "agent_reference",
      name: $agent_name
    }
  }')

http_request \
  --request POST \
  "$RESPONSES_URL" \
  --header "Authorization: Bearer ${FOUNDRY_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$PAYLOAD"

if [ "$HTTP_STATUS" != "200" ]; then
  print_http_body >&2
  delete_conversation_if_needed
  die "Unexpected agent response HTTP status ${HTTP_STATUS}; expected 200."
fi

OUTPUT_TEXT=$(jq -r '.output_text // ([.output[]? | select(.type == "message") | .content[]? | select(.type == "output_text") | .text] | join("\n"))' "$HTTP_BODY_FILE")
MCP_EVENT_COUNT=$(jq '[.output[]? | select((.type // "") | startswith("mcp"))] | length' "$HTTP_BODY_FILE")

[ -n "$OUTPUT_TEXT" ] || {
  print_http_body >&2
  delete_conversation_if_needed
  die "Agent response did not contain output text."
}
[ "$MCP_EVENT_COUNT" -gt 0 ] || {
  print_http_body >&2
  delete_conversation_if_needed
  die "Agent response did not contain an MCP tool event."
}

log "Question: ${QUESTION}"
log "MCP events: ${MCP_EVENT_COUNT}"
log "Answer:"
printf '%s\n' "$OUTPUT_TEXT"

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  log "Full response:"
  print_http_body
fi

delete_conversation_if_needed

FOUNDRY_TOKEN=""