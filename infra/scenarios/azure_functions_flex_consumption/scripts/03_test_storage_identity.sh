#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_common.sh"

[ "$#" -eq 0 ] || die "Usage: 03_test_storage_identity.sh"
load_outputs
require_command curl
require_output "$FUNCTION_APP_URL" function_app_url
require_output "$AUTH_IDENTIFIER_URI" function_app_authentication_identifier_uri
require_output "$STORAGE_ACCOUNT_NAME" storage_account_name
require_output "$DEPLOYMENT_CONTAINER_NAME" deployment_container_name
init_response_file
request "$FUNCTION_APP_URL/api/storage-check"
expect_status 401
access_token
request --header "Authorization: Be""arer $ACCESS_TOKEN" "$FUNCTION_APP_URL/api/storage-check"
if [ "$HTTP_STATUS" = 503 ]; then
  die "Storage probe returned HTTP 503. Check the Function App managed identity's Storage Blob RBAC assignment; allow time for RBAC propagation, then retry."
fi
expect_status 200
jq -e --arg container "$DEPLOYMENT_CONTAINER_NAME" \
  'type == "object" and (keys == ["container", "status"]) and
   .status == "ok" and .container == $container' "$RESPONSE_FILE" >/dev/null ||
  die "Storage probe did not report the expected container."
printf 'Storage probe verified for %s/%s.\n' "$STORAGE_ACCOUNT_NAME" "$DEPLOYMENT_CONTAINER_NAME"
