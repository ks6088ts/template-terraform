#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

require_command curl
require_command jq
require_command terraform

load_terraform_outputs
require_value container_app_url "$CONTAINER_APP_URL"

ACCESS_TOKEN=""
if [ -n "$AUTHENTICATION_IDENTIFIER_URI" ]; then
  require_command az
  ACCESS_TOKEN=$(az account get-access-token \
    --resource "$AUTHENTICATION_IDENTIFIER_URI" \
    --query accessToken \
    --output tsv)
  [ -n "$ACCESS_TOKEN" ] || die "Azure CLI returned an empty access token."
fi

HEALTH_RESPONSE_FILE=$(mktemp "${TMPDIR:-/tmp}/azure-container-apps-health.XXXXXX")
MCP_RESPONSE_FILE=$(mktemp "${TMPDIR:-/tmp}/azure-container-apps-mcp.XXXXXX")

cleanup() {
  rm -f "$HEALTH_RESPONSE_FILE" "$MCP_RESPONSE_FILE"
}

trap 'cleanup' 0
trap 'cleanup; exit 1' HUP INT TERM

if [ -n "$ACCESS_TOKEN" ]; then
  curl --fail --show-error --silent \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --output "$HEALTH_RESPONSE_FILE" \
    "${CONTAINER_APP_URL}/health"
else
  curl --fail --show-error --silent \
    --output "$HEALTH_RESPONSE_FILE" \
    "${CONTAINER_APP_URL}/health"
fi

jq -e '.status == "healthy"' "$HEALTH_RESPONSE_FILE" >/dev/null \
  || die "The health endpoint did not return the expected response."

if [ -n "$ACCESS_TOKEN" ]; then
  curl --fail --show-error --silent --no-buffer \
    --header "Authorization: Bearer ${ACCESS_TOKEN}" \
    --header "Content-Type: application/json" \
    --header "Accept: application/json, text/event-stream" \
    --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
    --output "$MCP_RESPONSE_FILE" \
    "${CONTAINER_APP_URL}/mcp"
else
  curl --fail --show-error --silent --no-buffer \
    --header "Content-Type: application/json" \
    --header "Accept: application/json, text/event-stream" \
    --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
    --output "$MCP_RESPONSE_FILE" \
    "${CONTAINER_APP_URL}/mcp"
fi

if jq -e '.id == 1 and ((.result.tools? | type) == "array")' "$MCP_RESPONSE_FILE" >/dev/null 2>&1; then
  :
elif sed -n 's/^data: //p' "$MCP_RESPONSE_FILE" \
  | jq -e -s 'any(.[]; .id == 1 and ((.result.tools? | type) == "array"))' >/dev/null; then
  :
else
  cat "$MCP_RESPONSE_FILE" >&2
  die "The MCP endpoint did not return a tools/list result."
fi

log "Deployment verification succeeded."
log "Container App URL: ${CONTAINER_APP_URL}"
