#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

usage() {
  cat <<'EOF'
Usage: verify_deployment.sh [OPTIONS]

Verify the deployed Container App health, MCP endpoint, and optional telemetry.

Options:
  -v, --verbose  Show request progress, HTTP status, MCP tools, and telemetry progress
  -h, --help     Show this help
EOF
}

VERBOSE=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    -v|--verbose) VERBOSE=true ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1. Use --help for usage." ;;
  esac
  shift
done

verbose_log() {
  if [ "$VERBOSE" = "true" ]; then
    log "$*"
  fi
}

require_command curl
require_command date
require_command jq
require_command terraform

verbose_log "Loading Terraform outputs..."
load_terraform_outputs
require_value container_app_url "$CONTAINER_APP_URL"
verbose_log "Container App URL: ${CONTAINER_APP_URL}"
VERIFY_STARTED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

ACCESS_TOKEN=""
if [ -n "$AUTHENTICATION_IDENTIFIER_URI" ]; then
  require_command az
  require_value subscription_id "$AZURE_SUBSCRIPTION_ID"
  verbose_log "Authentication: Microsoft Entra ID"
  verbose_log "Token audience: ${AUTHENTICATION_IDENTIFIER_URI}"
  ACCESS_TOKEN=$(az account get-access-token \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource "$AUTHENTICATION_IDENTIFIER_URI" \
    --query accessToken \
    --output tsv)
  [ -n "$ACCESS_TOKEN" ] || die "Azure CLI returned an empty access token."
  verbose_log "Access token acquired."
else
  verbose_log "Authentication: disabled"
fi

HEALTH_RESPONSE_FILE=$(mktemp "${TMPDIR:-/tmp}/azure-container-apps-health.XXXXXX")
MCP_RESPONSE_FILE=$(mktemp "${TMPDIR:-/tmp}/azure-container-apps-mcp.XXXXXX")

cleanup() {
  rm -f "$HEALTH_RESPONSE_FILE" "$MCP_RESPONSE_FILE"
}

trap 'cleanup' 0
trap 'cleanup; exit 1' HUP INT TERM

verbose_log "GET ${CONTAINER_APP_URL}/health"
if [ -n "$ACCESS_TOKEN" ]; then
  HEALTH_HTTP_STATUS=$(curl --fail --show-error --silent \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --output "$HEALTH_RESPONSE_FILE" \
    --write-out '%{http_code}' \
    "${CONTAINER_APP_URL}/health")
else
  HEALTH_HTTP_STATUS=$(curl --fail --show-error --silent \
    --output "$HEALTH_RESPONSE_FILE" \
    --write-out '%{http_code}' \
    "${CONTAINER_APP_URL}/health")
fi

jq -e '.status == "healthy"' "$HEALTH_RESPONSE_FILE" >/dev/null \
  || die "The health endpoint did not return the expected response."

if [ "$VERBOSE" = "true" ]; then
  log "Health response: HTTP ${HEALTH_HTTP_STATUS} $(jq -c . "$HEALTH_RESPONSE_FILE")"
fi

verbose_log "POST ${CONTAINER_APP_URL}/mcp (tools/list)"
if [ -n "$ACCESS_TOKEN" ]; then
  MCP_HTTP_STATUS=$(curl --fail --show-error --silent --no-buffer \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json, text/event-stream" \
    --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
    --output "$MCP_RESPONSE_FILE" \
    --write-out '%{http_code}' \
    "${CONTAINER_APP_URL}/mcp")
else
  MCP_HTTP_STATUS=$(curl --fail --show-error --silent --no-buffer \
    --header "Content-Type: application/json" \
    --header "Accept: application/json, text/event-stream" \
    --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
    --output "$MCP_RESPONSE_FILE" \
    --write-out '%{http_code}' \
    "${CONTAINER_APP_URL}/mcp")
fi
verbose_log "MCP response: HTTP ${MCP_HTTP_STATUS}"

if jq -e '.id == 1 and ((.result.tools? | type) == "array")' "$MCP_RESPONSE_FILE" >/dev/null 2>&1; then
  MCP_RESPONSE_FORMAT="application/json"
  MCP_TOOL_NAMES=$(jq -r '[.result.tools[].name] | join(", ")' "$MCP_RESPONSE_FILE")
elif sed -n 's/^data: //p' "$MCP_RESPONSE_FILE" \
  | jq -e -s 'any(.[]; .id == 1 and ((.result.tools? | type) == "array"))' >/dev/null; then
  MCP_RESPONSE_FORMAT="text/event-stream"
  MCP_TOOL_NAMES=$(sed -n 's/^data: //p' "$MCP_RESPONSE_FILE" \
    | jq -r -s '[.[] | select(.id == 1) | .result.tools[]?.name] | join(", ")')
else
  cat "$MCP_RESPONSE_FILE" >&2
  die "The MCP endpoint did not return a tools/list result."
fi

verbose_log "MCP response format: ${MCP_RESPONSE_FORMAT}"
verbose_log "MCP tools: ${MCP_TOOL_NAMES}"

if [ -n "$APPLICATION_INSIGHTS_APP_ID" ]; then
  require_command az
  require_command sleep
  require_value subscription_id "$AZURE_SUBSCRIPTION_ID"

  : "${TELEMETRY_MAX_ATTEMPTS:=12}"
  : "${TELEMETRY_RETRY_SECONDS:=10}"
  case "$TELEMETRY_MAX_ATTEMPTS" in
    ''|*[!0-9]*) die "TELEMETRY_MAX_ATTEMPTS must be a positive integer." ;;
  esac
  case "$TELEMETRY_RETRY_SECONDS" in
    ''|*[!0-9]*) die "TELEMETRY_RETRY_SECONDS must be a non-negative integer." ;;
  esac
  [ "$TELEMETRY_MAX_ATTEMPTS" -gt 0 ] || die "TELEMETRY_MAX_ATTEMPTS must be a positive integer."

  APP_INSIGHTS_API=$(az cloud show \
    --query endpoints.appInsightsResourceId \
    --output tsv)
  APP_INSIGHTS_API=${APP_INSIGHTS_API%/}
  [ -n "$APP_INSIGHTS_API" ] || die "Azure CLI returned an empty Application Insights API endpoint."

  TELEMETRY_QUERY="requests | where timestamp >= datetime(${VERIFY_STARTED_AT}) | where url endswith '/health' | take 1"
  TELEMETRY_REQUEST_BODY=$(jq -n --arg query "$TELEMETRY_QUERY" '{query: $query}')
  TELEMETRY_ATTEMPT=1
  TELEMETRY_FOUND=false

  verbose_log "Waiting for fresh Application Insights request telemetry..."
  while [ "$TELEMETRY_ATTEMPT" -le "$TELEMETRY_MAX_ATTEMPTS" ]; do
    TELEMETRY_RESPONSE=$(az rest \
      --method post \
      --url "${APP_INSIGHTS_API}/v1/apps/${APPLICATION_INSIGHTS_APP_ID}/query" \
      --resource "$APP_INSIGHTS_API" \
      --subscription "$AZURE_SUBSCRIPTION_ID" \
      --headers "Content-Type=application/json" \
      --body "$TELEMETRY_REQUEST_BODY" \
      --output json)

    if printf '%s' "$TELEMETRY_RESPONSE" \
      | jq -e 'any(.tables[]?; ((.rows // []) | length) > 0)' >/dev/null; then
      TELEMETRY_FOUND=true
      break
    fi

    if [ "$TELEMETRY_ATTEMPT" -lt "$TELEMETRY_MAX_ATTEMPTS" ]; then
      verbose_log "Telemetry not available yet (${TELEMETRY_ATTEMPT}/${TELEMETRY_MAX_ATTEMPTS}); retrying..."
      sleep "$TELEMETRY_RETRY_SECONDS"
    fi
    TELEMETRY_ATTEMPT=$((TELEMETRY_ATTEMPT + 1))
  done

  [ "$TELEMETRY_FOUND" = "true" ] \
    || die "Fresh Application Insights request telemetry was not found after ${TELEMETRY_MAX_ATTEMPTS} attempts."
  verbose_log "Application Insights telemetry found on attempt ${TELEMETRY_ATTEMPT}."
fi

log "Deployment verification succeeded."
log "Container App URL: ${CONTAINER_APP_URL}"
