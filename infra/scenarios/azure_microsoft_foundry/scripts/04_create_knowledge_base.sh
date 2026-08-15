#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name KNOWLEDGE_SOURCE_NAME "$KNOWLEDGE_SOURCE_NAME"
validate_resource_name KNOWLEDGE_BASE_NAME "$KNOWLEDGE_BASE_NAME"

SEARCH_TOKEN=$(get_access_token "https://search.azure.com/.default")
KNOWLEDGE_BASE_URL="${SEARCH_ENDPOINT}/knowledgebases('${KNOWLEDGE_BASE_NAME}')?api-version=${SEARCH_API_VERSION}"

PAYLOAD=$(jq -n \
  --arg name "$KNOWLEDGE_BASE_NAME" \
  --arg knowledge_source_name "$KNOWLEDGE_SOURCE_NAME" \
  '{
    name: $name,
    description: "Foundry IQ knowledge base for fictional restaurant reviews.",
    knowledgeSources: [
      {
        name: $knowledge_source_name
      }
    ],
    outputMode: "extractiveData",
    retrievalReasoningEffort: {
      kind: "minimal"
    }
  }')

http_request \
  --request PUT \
  "$KNOWLEDGE_BASE_URL" \
  --header "Authorization: Bearer ${SEARCH_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Prefer: return=representation" \
  --data "$PAYLOAD"

expect_http_status 200 201
SEARCH_TOKEN=""

log "Created or updated knowledge base: ${KNOWLEDGE_BASE_NAME}"
log "MCP endpoint: ${SEARCH_ENDPOINT}/knowledgebases/${KNOWLEDGE_BASE_NAME}/mcp?api-version=${SEARCH_API_VERSION}"

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  print_http_body
fi