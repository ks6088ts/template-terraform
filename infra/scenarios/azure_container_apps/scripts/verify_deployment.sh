#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

usage() {
  cat <<'EOF'
Usage: verify_deployment.sh [OPTIONS]

Verify the deployed Container App health and MCP endpoints.

Options:
  -v, --verbose  Show request progress, HTTP status, and MCP tool names
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
require_command jq
require_command terraform

verbose_log "Loading Terraform outputs..."
load_terraform_outputs
require_value container_app_url "$CONTAINER_APP_URL"
verbose_log "Container App URL: ${CONTAINER_APP_URL}"

ACCESS_TOKEN=""
if [ -n "$AUTHENTICATION_IDENTIFIER_URI" ]; then
  require_command az
  verbose_log "Authentication: Microsoft Entra ID"
  verbose_log "Token audience: ${AUTHENTICATION_IDENTIFIER_URI}"
  ACCESS_TOKEN=$(az account get-access-token \
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

log "Deployment verification succeeded."
log "Container App URL: ${CONTAINER_APP_URL}"
