#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

QUESTION=${*:-Which fictional restaurants offer vegan options, and what did reviewers say about them?}

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name KNOWLEDGE_SOURCE_NAME "$KNOWLEDGE_SOURCE_NAME"
validate_resource_name KNOWLEDGE_BASE_NAME "$KNOWLEDGE_BASE_NAME"

SEARCH_TOKEN=$(get_access_token "https://search.azure.com/.default")
RETRIEVE_URL="${SEARCH_ENDPOINT}/knowledgebases('${KNOWLEDGE_BASE_NAME}')/retrieve?api-version=${SEARCH_API_VERSION}"

PAYLOAD=$(jq -n \
  --arg question "$QUESTION" \
  --arg knowledge_source_name "$KNOWLEDGE_SOURCE_NAME" \
  '{
    intents: [
      {
        type: "semantic",
        search: $question
      }
    ],
    outputMode: "extractiveData",
    retrievalReasoningEffort: {
      kind: "minimal"
    },
    includeActivity: true,
    knowledgeSourceParams: [
      {
        knowledgeSourceName: $knowledge_source_name,
        kind: "azureBlob",
        includeReferences: true,
        includeReferenceSourceData: true,
        alwaysQuerySource: true,
        failOnError: true
      }
    ]
  }')

http_request \
  --request POST \
  "$RETRIEVE_URL" \
  --header "Authorization: Bearer ${SEARCH_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$PAYLOAD"

expect_http_status 200
SEARCH_TOKEN=""

GROUNDING_TEXT=$(jq -r '[.response[]?.content[]? | select(.type == "text") | .text] | join("\n")' "$HTTP_BODY_FILE")

log "Question: ${QUESTION}"
log "Grounding response:"
if [ -z "$GROUNDING_TEXT" ]; then
  log "(No grounding content returned.)"
elif printf '%s' "$GROUNDING_TEXT" | jq . 2>/dev/null; then
  :
else
  printf '%s\n' "$GROUNDING_TEXT"
fi

log "References:"
if ! jq -e '.references | length > 0' "$HTTP_BODY_FILE" >/dev/null 2>&1; then
  log "(No references returned.)"
else
  jq -r '.references[] | "- type=\(.type) source=\(.blobUrl // .docKey // .id) score=\(.rerankerScore // "n/a")"' "$HTTP_BODY_FILE"
fi

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  log "Full response:"
  print_http_body
fi