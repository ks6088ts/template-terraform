#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name KNOWLEDGE_BASE_NAME "$KNOWLEDGE_BASE_NAME"
validate_resource_name PROJECT_CONNECTION_NAME "$PROJECT_CONNECTION_NAME"

ARM_TOKEN=$(get_access_token "https://management.azure.com/.default")
MCP_ENDPOINT="${SEARCH_ENDPOINT}/knowledgebases/${KNOWLEDGE_BASE_NAME}/mcp?api-version=${SEARCH_API_VERSION}"
CONNECTION_URL="https://management.azure.com${PROJECT_ID}/connections/${PROJECT_CONNECTION_NAME}?api-version=${PROJECT_CONNECTION_API_VERSION}"

PAYLOAD=$(jq -n \
  --arg name "$PROJECT_CONNECTION_NAME" \
  --arg target "$MCP_ENDPOINT" \
  '{
    name: $name,
    type: "Microsoft.MachineLearningServices/workspaces/connections",
    properties: {
      authType: "ProjectManagedIdentity",
      category: "RemoteTool",
      target: $target,
      isSharedToAll: true,
      audience: "https://search.azure.com/",
      metadata: {
        ApiType: "Azure"
      }
    }
  }')

http_request \
  --request PUT \
  "$CONNECTION_URL" \
  --header "Authorization: Bearer ${ARM_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --data "$PAYLOAD"

expect_http_status 200 201
ARM_TOKEN=""

log "Created or updated Foundry RemoteTool connection: ${PROJECT_CONNECTION_NAME}"
log "Target MCP endpoint: ${MCP_ENDPOINT}"

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  print_http_body
fi