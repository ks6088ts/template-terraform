#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${INGESTION_TIMEOUT_SECONDS:=900}"
: "${POLL_INTERVAL_SECONDS:=10}"

require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name KNOWLEDGE_SOURCE_NAME "$KNOWLEDGE_SOURCE_NAME"
validate_positive_integer INGESTION_TIMEOUT_SECONDS "$INGESTION_TIMEOUT_SECONDS"
validate_positive_integer POLL_INTERVAL_SECONDS "$POLL_INTERVAL_SECONDS"

SEARCH_TOKEN=$(get_access_token "https://search.azure.com/.default")
STATUS_URL="${SEARCH_ENDPOINT}/knowledgesources('${KNOWLEDGE_SOURCE_NAME}')/status?api-version=${SEARCH_API_VERSION}"
START_EPOCH=$(date +%s)
TARGET_START_TIME=""

while :; do
  http_request \
    --request GET \
    "$STATUS_URL" \
    --header "Authorization: Bearer ${SEARCH_TOKEN}" \
    --header "Accept: application/json"
  expect_http_status 200

  SYNCHRONIZATION_STATUS=$(jq -r '.synchronizationStatus // "unknown"' "$HTTP_BODY_FILE")
  CURRENT_START_TIME=$(jq -r '.currentSynchronizationState.startTime // empty' "$HTTP_BODY_FILE")
  LAST_START_TIME=$(jq -r '.lastSynchronizationState.startTime // empty' "$HTTP_BODY_FILE")
  LAST_END_TIME=$(jq -r '.lastSynchronizationState.endTime // empty' "$HTTP_BODY_FILE")
  CURRENT_PROCESSED=$(jq -r '.currentSynchronizationState.itemsUpdatesProcessed // 0' "$HTTP_BODY_FILE")
  CURRENT_FAILED=$(jq -r '.currentSynchronizationState.itemsUpdatesFailed // 0' "$HTTP_BODY_FILE")
  LAST_PROCESSED=$(jq -r '.lastSynchronizationState.itemsUpdatesProcessed // 0' "$HTTP_BODY_FILE")
  LAST_FAILED=$(jq -r '.lastSynchronizationState.itemsUpdatesFailed // 0' "$HTTP_BODY_FILE")

  if [ -z "$TARGET_START_TIME" ] && [ -n "$CURRENT_START_TIME" ]; then
    TARGET_START_TIME=$CURRENT_START_TIME
  fi

  log "Ingestion status=${SYNCHRONIZATION_STATUS} current_processed=${CURRENT_PROCESSED} current_failed=${CURRENT_FAILED} last_processed=${LAST_PROCESSED} last_failed=${LAST_FAILED}"

  if [ "$CURRENT_FAILED" -gt 0 ]; then
    jq -r '.currentSynchronizationState.errors[]? | "\(.name // "unknown component"): \(.errorMessage // .details // "unknown error")"' "$HTTP_BODY_FILE" >&2
  fi

  COMPLETED_TARGET=false
  if [ -n "$LAST_END_TIME" ]; then
    if [ -z "$TARGET_START_TIME" ] || [ "$LAST_START_TIME" = "$TARGET_START_TIME" ]; then
      COMPLETED_TARGET=true
    fi
  fi

  if [ "$COMPLETED_TARGET" = "true" ]; then
    if [ "$LAST_FAILED" -eq 0 ]; then
      SEARCH_TOKEN=""
      log "Knowledge source ingestion completed successfully with ${LAST_PROCESSED} processed item(s)."
      exit 0
    fi

    print_http_body >&2
    die "Knowledge source ingestion completed with ${LAST_FAILED} failed item(s)."
  fi

  NOW_EPOCH=$(date +%s)
  ELAPSED_SECONDS=$((NOW_EPOCH - START_EPOCH))
  if [ "$ELAPSED_SECONDS" -ge "$INGESTION_TIMEOUT_SECONDS" ]; then
    print_http_body >&2
    die "Timed out after ${INGESTION_TIMEOUT_SECONDS} seconds waiting for knowledge source ingestion."
  fi

  sleep "$POLL_INTERVAL_SECONDS"
done