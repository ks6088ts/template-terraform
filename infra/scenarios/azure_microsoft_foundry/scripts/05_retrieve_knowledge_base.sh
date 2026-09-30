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

expect_http_status 200 206
SEARCH_TOKEN=""

GROUNDING_TEXT=$(jq -r '[.response[]?.content[]? | select(.type == "text") | .text] | join("\n")' "$HTTP_BODY_FILE")
REFERENCE_COUNT=$(jq -r '.references | length' "$HTTP_BODY_FILE")

[ -n "$GROUNDING_TEXT" ] || {
  print_http_body >&2
  die "Knowledge retrieval returned no grounding content."
}
[ "$REFERENCE_COUNT" -gt 0 ] || {
  print_http_body >&2
  die "Knowledge retrieval returned no grounding references."
}

if [ "$HTTP_STATUS" = "206" ]; then
  log "Knowledge retrieval returned partial content; inspect activity details before production use."
fi

log "Question: ${QUESTION}"
log "Grounding response:"
if printf '%s' "$GROUNDING_TEXT" | jq . 2>/dev/null; then
  :
else
  printf '%s\n' "$GROUNDING_TEXT"
fi

log "References (${REFERENCE_COUNT}):"
jq -r '.references[] | "- type=\(.type) source=\(.blobUrl // .docKey // .id) score=\(.rerankerScore // "n/a")"' "$HTTP_BODY_FILE"

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  log "Full response:"
  print_http_body
fi