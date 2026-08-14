#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
require_model_deployment "$AGENT_MODEL"
validate_resource_name KNOWLEDGE_BASE_NAME "$KNOWLEDGE_BASE_NAME"
validate_resource_name PROJECT_CONNECTION_NAME "$PROJECT_CONNECTION_NAME"
validate_resource_name AGENT_NAME "$AGENT_NAME"

FOUNDRY_TOKEN=$(get_access_token "https://ai.azure.com/.default")
MCP_ENDPOINT="${SEARCH_ENDPOINT}/knowledgebases/${KNOWLEDGE_BASE_NAME}/mcp?api-version=${SEARCH_API_VERSION}"
AGENT_URL="${PROJECT_ENDPOINT}/agents?api-version=${AGENT_API_VERSION}"
AGENT_INSTRUCTIONS='You are a restaurant Q&A assistant. You must use the knowledge base tool for every user question. Answer only with facts supported by the retrieved fictional restaurant data. Include source citations or source URLs from the tool result whenever evidence is available. If the knowledge base does not contain enough evidence, respond exactly with: I do not know.'

PAYLOAD=$(jq -n \
  --arg name "$AGENT_NAME" \
  --arg model "$AGENT_MODEL" \
  --arg instructions "$AGENT_INSTRUCTIONS" \
  --arg server_url "$MCP_ENDPOINT" \
  --arg connection_name "$PROJECT_CONNECTION_NAME" \
  '{
    name: $name,
    definition: {
      model: $model,
      instructions: $instructions,
      tools: [
        {
          type: "mcp",
          server_label: "restaurant-knowledge-base",
          server_url: $server_url,
          allowed_tools: [
            "knowledge_base_retrieve"
          ],
          project_connection_id: $connection_name,
          require_approval: "never"
        }
      ],
      kind: "prompt"
    }
  }')

http_request \
  --request POST \
  "$AGENT_URL" \
  --header "Authorization: Bearer ${FOUNDRY_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$PAYLOAD"

expect_http_status 200 201
FOUNDRY_TOKEN=""

CREATED_AGENT_NAME=$(jq -r '.name // empty' "$HTTP_BODY_FILE")
CREATED_AGENT_VERSION=$(jq -r '.version // empty' "$HTTP_BODY_FILE")

log "Created Foundry agent version: ${CREATED_AGENT_NAME:-$AGENT_NAME}${CREATED_AGENT_VERSION:+ version ${CREATED_AGENT_VERSION}}"
log "Rerunning this script creates another version of the same named agent."

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  print_http_body
fi