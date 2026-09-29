#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_common.sh"

[ "$#" -eq 0 ] || die "Usage: 02_test_function_key.sh"
load_outputs
require_command curl
require_output "$FUNCTION_APP_URL" function_app_url
require_output "$AUTH_IDENTIFIER_URI" function_app_authentication_identifier_uri
init_response_file
request "$FUNCTION_APP_URL/api/hello-key?name=Azure"
expect_status 401
access_token
request --header "Authorization: Be""arer $ACCESS_TOKEN" "$FUNCTION_APP_URL/api/hello-key?name=Azure"
expect_status 401
function_key
request --header "x-functions-key: $FUNCTION_KEY" "$FUNCTION_APP_URL/api/hello-key?name=Azure"
expect_status 200
[ "$(cat "$RESPONSE_FILE")" = 'Hello, Azure!' ] || die "Unexpected Function key response."
printf 'Function key verified (401 without key and with bearer only, 200 with key).\n'
