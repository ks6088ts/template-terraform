#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${INGESTION_TIMEOUT_SECONDS:=900}"
: "${POLL_INTERVAL_SECONDS:=10}"

parse_common_options "$@"
verbose_log "Checking for a fresh knowledge source ingestion run."
require_common_commands
load_terraform_outputs
require_standard_agent_outputs
validate_resource_name KNOWLEDGE_SOURCE_NAME "$KNOWLEDGE_SOURCE_NAME"
validate_positive_integer INGESTION_TIMEOUT_SECONDS "$INGESTION_TIMEOUT_SECONDS"
validate_positive_integer POLL_INTERVAL_SECONDS "$POLL_INTERVAL_SECONDS"

SEARCH_TOKEN=$(get_access_token "https://search.azure.com/.default")
KNOWLEDGE_SOURCE_URL="${SEARCH_ENDPOINT}/knowledgesources('${KNOWLEDGE_SOURCE_NAME}')?api-version=${SEARCH_API_VERSION}"
STATUS_URL="${SEARCH_ENDPOINT}/knowledgesources('${KNOWLEDGE_SOURCE_NAME}')/status?api-version=${SEARCH_API_VERSION}"
START_EPOCH=$(date +%s)
TARGET_START_TIME=""
BASELINE_LAST_START_TIME=""
RUN_REQUESTED=false

get_ingestion_status() {
  http_request \
    --request GET \
    "$STATUS_URL" \
    --header "Authorization: Bearer ${SEARCH_TOKEN}" \
    --header "Accept: application/json"
  expect_http_status 200
}

get_ingestion_status
TARGET_START_TIME=$(jq -r '.currentSynchronizationState.startTime // empty' "$HTTP_BODY_FILE")
BASELINE_LAST_START_TIME=$(jq -r '.lastSynchronizationState.startTime // empty' "$HTTP_BODY_FILE")

if [ -n "$TARGET_START_TIME" ]; then
  log "Waiting for active knowledge source ingestion: ${TARGET_START_TIME}"
else
  http_request \
    --request GET \
    "$KNOWLEDGE_SOURCE_URL" \
    --header "Authorization: Bearer ${SEARCH_TOKEN}" \
    --header "Accept: application/json"
  expect_http_status 200

  INDEXER_NAME=$(jq -r '.azureBlobParameters.createdResources.indexer // empty' "$HTTP_BODY_FILE")
  [ -n "$INDEXER_NAME" ] || die "Knowledge source response did not identify its generated indexer."
  validate_resource_name INDEXER_NAME "$INDEXER_NAME"

  RUN_URL="${SEARCH_ENDPOINT}/indexers('${INDEXER_NAME}')/search.run?api-version=${SEARCH_API_VERSION}"
  http_request \
    --request POST \
    "$RUN_URL" \
    --header "Authorization: Bearer ${SEARCH_TOKEN}" \
    --header "Accept: application/json" \
    --header "Content-Length: 0"

  case "$HTTP_STATUS" in
    202)
      log "Started a fresh ingestion run with generated indexer: ${INDEXER_NAME}"
      ;;
    409)
      if jq -e '
        ((.error.code // "") | test("already.*running|inprogress"; "i")) or
        ((.error.message // "") | test("already.*running|in progress"; "i"))
      ' "$HTTP_BODY_FILE" >/dev/null 2>&1; then
        log "Generated indexer is already running: ${INDEXER_NAME}"
      else
        print_http_body >&2
        die "Generated indexer returned an unexpected conflict."
      fi
      ;;
    *)
      expect_http_status 202
      ;;
  esac
  RUN_REQUESTED=true
fi

while :; do
  get_ingestion_status

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
  if [ -n "$LAST_END_TIME" ] && [ -n "$TARGET_START_TIME" ] && [ "$LAST_START_TIME" = "$TARGET_START_TIME" ]; then
    COMPLETED_TARGET=true
  elif [ "$RUN_REQUESTED" = "true" ] &&
    [ -n "$LAST_END_TIME" ] &&
    [ "$LAST_START_TIME" != "$BASELINE_LAST_START_TIME" ]; then
    TARGET_START_TIME=$LAST_START_TIME
    COMPLETED_TARGET=true
  fi

  if [ "$COMPLETED_TARGET" = "true" ]; then
    if [ "$LAST_FAILED" -gt 0 ]; then
      print_http_body >&2
      die "Knowledge source ingestion completed with ${LAST_FAILED} failed item(s)."
    fi
    if [ "$LAST_PROCESSED" -le 0 ]; then
      print_http_body >&2
      die "Knowledge source ingestion completed without processing any items."
    fi

    SEARCH_TOKEN=""
    log "Knowledge source ingestion ${TARGET_START_TIME} completed successfully with ${LAST_PROCESSED} processed item(s)."
    exit 0
  fi

  NOW_EPOCH=$(date +%s)
  ELAPSED_SECONDS=$((NOW_EPOCH - START_EPOCH))
  verbose_log "Ingestion wait elapsed=${ELAPSED_SECONDS}s timeout=${INGESTION_TIMEOUT_SECONDS}s."
  if [ "$ELAPSED_SECONDS" -ge "$INGESTION_TIMEOUT_SECONDS" ]; then
    print_http_body >&2
    die "Timed out after ${INGESTION_TIMEOUT_SECONDS} seconds waiting for a fresh knowledge source ingestion."
  fi

  sleep "$POLL_INTERVAL_SECONDS"
done
