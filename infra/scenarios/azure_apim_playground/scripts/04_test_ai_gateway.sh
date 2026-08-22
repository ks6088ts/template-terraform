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

PAYLOAD=$(jq -n \
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
  --data "$PAYLOAD"
expect_http_status 200

jq -e '
  .choices
  | type == "array" and any(.[]; (.message.content // "") | length > 0)
' "$HTTP_BODY_FILE" >/dev/null || die "AI gateway response did not contain completion text."

log "AI gateway returned a completion through managed-identity backend authentication."
log "Deployment: ${AI_DEPLOYMENT_NAME}"
