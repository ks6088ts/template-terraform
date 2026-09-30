#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${CLEANUP_AFTER_RUN:=false}"
validate_boolean CLEANUP_AFTER_RUN "$CLEANUP_AFTER_RUN"

run_step() {
  STEP_LABEL=$1
  STEP_SCRIPT=$2
  shift 2

  log ""
  log "== ${STEP_LABEL} =="
  if "${SCRIPT_DIR}/${STEP_SCRIPT}" "$@"; then
    return 0
  else
    STEP_EXIT_CODE=$?
  fi

  if [ "$CLEANUP_AFTER_RUN" = "true" ]; then
    log ""
    log "== Cleanup after failed step =="
    if ! CONFIRM_CLEANUP=delete-foundry-iq-resources "${SCRIPT_DIR}/09_cleanup.sh"; then
      log "Warning: cleanup also failed."
    fi
  fi

  exit "$STEP_EXIT_CODE"
}

run_step "Validate prerequisites" "00_validate_prerequisites.sh"
run_step "Upload restaurant reviews" "01_upload_restaurant_reviews.sh"
run_step "Create knowledge source" "02_create_knowledge_source.sh"
run_step "Wait for fresh ingestion" "03_wait_for_ingestion.sh"
run_step "Create knowledge base" "04_create_knowledge_base.sh"
run_step "Verify direct retrieval" "05_retrieve_knowledge_base.sh"
run_step "Create MCP project connection" "06_create_project_connection.sh"
run_step "Create prompt-agent version" "07_create_agent.sh"
run_step "Verify grounded agent response" "08_ask_agent.sh"

if [ "$CLEANUP_AFTER_RUN" = "true" ]; then
  log ""
  log "== Cleanup after successful run =="
  CONFIRM_CLEANUP=delete-foundry-iq-resources "${SCRIPT_DIR}/09_cleanup.sh"
fi

log ""
log "All Microsoft Foundry scenario checks passed."
