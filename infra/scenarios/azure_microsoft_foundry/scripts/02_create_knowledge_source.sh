#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
require_model_deployment "$EMBEDDING_DEPLOYMENT"
validate_resource_name CONTAINER_NAME "$CONTAINER_NAME"
validate_resource_name KNOWLEDGE_SOURCE_NAME "$KNOWLEDGE_SOURCE_NAME"

SEARCH_TOKEN=$(get_access_token "https://search.azure.com/.default")
KNOWLEDGE_SOURCE_URL="${SEARCH_ENDPOINT}/knowledgesources('${KNOWLEDGE_SOURCE_NAME}')?api-version=${SEARCH_API_VERSION}"

PAYLOAD=$(jq -n \
  --arg name "$KNOWLEDGE_SOURCE_NAME" \
  --arg storage_resource_id "$STORAGE_ACCOUNT_ID" \
  --arg container_name "$CONTAINER_NAME" \
  --arg openai_endpoint "$FOUNDRY_OPENAI_ENDPOINT" \
  --arg embedding_deployment "$EMBEDDING_DEPLOYMENT" \
  --arg embedding_model "$EMBEDDING_MODEL" \
  '{
    name: $name,
    kind: "azureBlob",
    description: "Fictional restaurant reviews uploaded as an English CSV file.",
    azureBlobParameters: {
      connectionString: ("ResourceId=" + $storage_resource_id + ";"),
      containerName: $container_name,
      folderPath: null,
      isADLSGen2: false,
      ingestionParameters: {
        disableImageVerbalization: true,
        contentExtractionMode: "minimal",
        embeddingModel: {
          kind: "azureOpenAI",
          azureOpenAIParameters: {
            resourceUri: $openai_endpoint,
            deploymentId: $embedding_deployment,
            modelName: $embedding_model
          }
        },
        ingestionSchedule: null
      }
    }
  }')

http_request \
  --request PUT \
  "$KNOWLEDGE_SOURCE_URL" \
  --header "Authorization: Bearer ${SEARCH_TOKEN}" \
  --header "Content-Type: application/json" \
  --header "Accept: application/json" \
  --header "Prefer: return=representation" \
  --data "$PAYLOAD"

expect_http_status 200 201
SEARCH_TOKEN=""

log "Created or updated knowledge source: ${KNOWLEDGE_SOURCE_NAME}"
if jq -e '.azureBlobParameters.createdResources != null' "$HTTP_BODY_FILE" >/dev/null 2>&1; then
  jq -r '.azureBlobParameters.createdResources | to_entries[] | "\(.key): \(.value)"' "$HTTP_BODY_FILE"
fi

if [ "$VERBOSE_OUTPUT" = "true" ]; then
  print_http_body
fi