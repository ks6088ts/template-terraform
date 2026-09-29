#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${AI_PROMPT:=Reply with exactly: APIM gateway verified}"
: "${AI_MAX_TOKENS:=64}"

require_common_commands
load_terraform_outputs
require_core_outputs
require_feature ai_backend "$AI_BACKEND_ENABLED"
require_value ai_gateway_url "$AI_GATEWAY_URL"
require_value ai_deployment_name "$AI_DEPLOYMENT_NAME"
validate_positive_integer AI_MAX_TOKENS "$AI_MAX_TOKENS"

CHAT_PAYLOAD=$(jq -n \
  --arg model "$AI_DEPLOYMENT_NAME" \
  --arg prompt "$AI_PROMPT" \
  --arg reasoning_effort "$AI_REASONING_EFFORT" \
  --argjson max_completion_tokens "$AI_MAX_TOKENS" \
  '{
    model: $model,
    messages: [
      {
        role: "user",
        content: $prompt
      }
    ],
    max_completion_tokens: $max_completion_tokens,
    stream: false
  } + (if $reasoning_effort == "" then {} else {reasoning_effort: $reasoning_effort} end)')

http_request \
  --request POST \
  "${AI_GATEWAY_URL}/chat/completions" \
  --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$CHAT_PAYLOAD"
expect_http_status 200

jq -e '
  .choices
  | type == "array" and any(.[]; (.message.content // "") | length > 0)
' "$HTTP_BODY_FILE" >/dev/null || die "AI gateway response did not contain completion text."

log "Chat Completions returned a non-streaming response."

CHAT_STREAM_PAYLOAD=$(printf '%s' "$CHAT_PAYLOAD" | jq '.stream = true')
http_request \
  --request POST \
  "${AI_GATEWAY_URL}/chat/completions" \
  --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: text/event-stream" \
  --data "$CHAT_STREAM_PAYLOAD"
expect_http_status 200
grep -q '^data:' "$HTTP_BODY_FILE" || die "Streaming Chat Completions response did not contain SSE data."
grep -q '"usage"' "$HTTP_BODY_FILE" || die "Streaming Chat Completions response did not contain token usage."
log "Chat Completions returned a streaming response with usage."

CHAT_STREAM_WITH_USAGE_PAYLOAD=$(printf '%s' "$CHAT_STREAM_PAYLOAD" | jq '.stream_options.include_usage = true')
http_request \
  --request POST \
  "${AI_GATEWAY_URL}/chat/completions" \
  --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: text/event-stream" \
  --data "$CHAT_STREAM_WITH_USAGE_PAYLOAD"
expect_http_status 200
grep -q '"usage"' "$HTTP_BODY_FILE" || die "Client-supplied streaming usage was not preserved."
log "Chat Completions preserved client-supplied streaming usage."

RESPONSE_PAYLOAD=$(jq -n \
  --arg model "$AI_DEPLOYMENT_NAME" \
  --arg prompt "$AI_PROMPT" \
  --argjson max_output_tokens "$AI_MAX_TOKENS" \
  '{
    model: $model,
    input: $prompt,
    max_output_tokens: $max_output_tokens,
    stream: false,
    store: false
  }')

http_request \
  --request POST \
  "${AI_GATEWAY_URL}/responses" \
  --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$RESPONSE_PAYLOAD"
expect_http_status 200
jq -e '
  (.id // "") | length > 0
' "$HTTP_BODY_FILE" >/dev/null || die "Responses API did not return a response ID."
log "Responses API returned a non-streaming stateless response."

RESPONSE_STREAM_PAYLOAD=$(printf '%s' "$RESPONSE_PAYLOAD" | jq '.stream = true')
http_request \
  --request POST \
  "${AI_GATEWAY_URL}/responses" \
  --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
  --header "Content-Type: application/json" \
  --header "Accept: text/event-stream" \
  --data "$RESPONSE_STREAM_PAYLOAD"
expect_http_status 200
grep -q 'response.completed' "$HTTP_BODY_FILE" || die "Streaming Responses API output did not reach response.completed."
log "Responses API returned a streaming stateless response."

log "All AI gateway paths used managed-identity backend authentication."
log "Deployment: ${AI_DEPLOYMENT_NAME}"
