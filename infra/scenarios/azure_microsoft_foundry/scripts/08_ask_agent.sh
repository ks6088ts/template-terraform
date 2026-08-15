#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

QUESTION=${*:-Which fictional restaurant is a strong choice for a vegan dinner, and why?}

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name AGENT_NAME "$AGENT_NAME"

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

expect_http_status 200
FOUNDRY_TOKEN=""

OUTPUT_TEXT=$(jq -r '.output_text // ([.output[]? | select(.type == "message") | .content[]? | select(.type == "output_text") | .text] | join("\n"))' "$HTTP_BODY_FILE")
MCP_EVENT_COUNT=$(jq '[.output[]? | select((.type // "") | startswith("mcp"))] | length' "$HTTP_BODY_FILE")

log "Conversation: ${CONVERSATION_ID}"
log "Question: ${QUESTION}"
log "MCP events: ${MCP_EVENT_COUNT}"
log "Answer:"
if [ -n "$OUTPUT_TEXT" ]; then
  printf '%s\n' "$OUTPUT_TEXT"
else
  log "(No output text returned. Set VERBOSE_OUTPUT=true to inspect the full response.)"
fi

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  log "Full response:"
  print_http_body
fi