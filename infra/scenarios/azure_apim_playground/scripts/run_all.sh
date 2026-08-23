#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${CLEANUP_AFTER_RUN:=false}"

run_step() {
  STEP_LABEL=$1
  STEP_SCRIPT=$2
  log ""
  log "== ${STEP_LABEL} =="
  if sh "${SCRIPT_DIR}/${STEP_SCRIPT}"; then
    return 0
  else
    STEP_EXIT_CODE=$?
  fi

  if [ "$CLEANUP_AFTER_RUN" = "true" ] && [ "$STEP_SCRIPT" != "09_cleanup.sh" ]; then
    log ""
    log "== Data-plane cleanup after failed step =="
    if ! CONFIRM_CLEANUP=delete-apim-playground-data sh "${SCRIPT_DIR}/09_cleanup.sh"; then
      log "Warning: data-plane cleanup also failed."
    fi
  fi

  exit "$STEP_EXIT_CODE"
}

skip_step() {
  log ""
  log "== Skip: $1 =="
}

require_common_commands
load_terraform_outputs

run_step "Prerequisites" "00_validate_prerequisites.sh"
run_step "Core API and subscription rate limit" "01_test_core.sh"

if [ "$BACKEND_POOL_ENABLED" = "true" ]; then
  run_step "Weighted backend routing" "02_test_weighted_routing.sh"
else
  skip_step "Weighted backend routing (backend_pool is disabled)"
fi

if [ "$CIRCUIT_BREAKER_ENABLED" = "true" ]; then
  run_step "Circuit-breaker priority failover" "03_test_failover.sh"
else
  skip_step "Circuit-breaker failover (circuit_breaker is disabled)"
fi

if [ "$CONTENT_SAFETY_ENABLED" = "true" ]; then
  run_step "Content Safety blocklist" "06_test_content_safety.sh"
else
  skip_step "Content Safety (content_safety is disabled)"
fi

if [ "$AI_BACKEND_ENABLED" = "true" ]; then
  run_step "AI gateway managed identity" "04_test_ai_gateway.sh"
else
  skip_step "AI gateway (ai_backend is disabled)"
fi

if [ "$LLM_TOKEN_LIMIT_ENABLED" = "true" ]; then
  run_step "LLM token limit" "05_test_token_limit.sh"
else
  skip_step "LLM token limit (llm_token_limit is disabled)"
fi

if [ "$LLM_LOGGING_ENABLED" = "true" ]; then
  run_step "Azure Monitor LLM logs" "07_test_llm_logs.sh"
else
  skip_step "Azure Monitor LLM logs (llm_logging is disabled)"
fi

if [ "$LLM_TOKEN_METRICS_ENABLED" = "true" ]; then
  run_step "Application Insights token metrics" "08_test_custom_metrics.sh"
else
  skip_step "Application Insights token metrics (llm_token_metrics is disabled)"
fi

if [ "$CLEANUP_AFTER_RUN" = "true" ]; then
  CONFIRM_CLEANUP=delete-apim-playground-data \
    run_step "Data-plane cleanup" "09_cleanup.sh"
fi

log ""
log "All enabled API Management playground checks passed."
