#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${TOKEN_LIMIT_ATTEMPTS:=30}"
: "${TOKEN_LIMIT_MAX_TOKENS:=1}"
: "${TOKEN_LIMIT_PROMPT:=Summarize this request in one word. This deliberately repeated prompt consumes enough input tokens to exercise the configured API Management language model token counter without returning a long completion. Summarize this request in one word. This deliberately repeated prompt consumes enough input tokens to exercise the configured API Management language model token counter without returning a long completion.}"

require_common_commands
load_terraform_outputs
require_core_outputs
require_feature llm_token_limit "$LLM_TOKEN_LIMIT_ENABLED"
require_feature ai_backend "$AI_BACKEND_ENABLED"
require_value ai_gateway_url "$AI_GATEWAY_URL"
require_value ai_deployment_name "$AI_DEPLOYMENT_NAME"
validate_positive_integer TOKEN_LIMIT_ATTEMPTS "$TOKEN_LIMIT_ATTEMPTS"
validate_positive_integer TOKEN_LIMIT_MAX_TOKENS "$TOKEN_LIMIT_MAX_TOKENS"

PAYLOAD=$(jq -n \
  --arg model "$AI_DEPLOYMENT_NAME" \
  --arg prompt "$TOKEN_LIMIT_PROMPT" \
  --argjson max_tokens "$TOKEN_LIMIT_MAX_TOKENS" \
  '{
    model: $model,
    messages: [
      {
        role: "user",
        content: $prompt
      }
    ],
    max_tokens: $max_tokens,
    stream: false
  }')

ATTEMPT=1
RATE_LIMIT_OBSERVED=false
TOKENS_CONSUMED_HEADER=""
while [ "$ATTEMPT" -le "$TOKEN_LIMIT_ATTEMPTS" ]; do
  http_request \
    --request POST \
    "${AI_GATEWAY_URL}/chat/completions" \
    --header "api-key: ${PLAYGROUND_SUBSCRIPTION_KEY}" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json" \
    --data "$PAYLOAD"

  case "$HTTP_STATUS" in
    200)
      CURRENT_TOKENS_CONSUMED=$(response_header x-llm-tokens-consumed)
      if [ -n "$CURRENT_TOKENS_CONSUMED" ]; then
        TOKENS_CONSUMED_HEADER=$CURRENT_TOKENS_CONSUMED
      fi
      ;;
    429)
      RATE_LIMIT_OBSERVED=true
      break
      ;;
    *)
      print_http_body >&2
      die "Token-limit exercise returned unexpected HTTP status ${HTTP_STATUS}."
      ;;
  esac
  ATTEMPT=$((ATTEMPT + 1))
done

[ "$RATE_LIMIT_OBSERVED" = "true" ] \
  || die "LLM token limit did not return 429 within ${TOKEN_LIMIT_ATTEMPTS} requests. Use a lower profile limit or increase TOKEN_LIMIT_ATTEMPTS."

log "LLM token limit returned HTTP 429."
if [ -n "$TOKENS_CONSUMED_HEADER" ]; then
  log "Observed x-llm-tokens-consumed before throttling: ${TOKENS_CONSUMED_HEADER}"
fi
