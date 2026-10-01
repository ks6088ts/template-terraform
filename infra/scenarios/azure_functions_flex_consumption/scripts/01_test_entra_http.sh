#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_common.sh"

[ "$#" -eq 0 ] || die "Usage: 01_test_entra_http.sh"
load_outputs
[ -n "$AUTH_IDENTIFIER_URI" ] || {
  printf 'Easy Auth check skipped because authentication is disabled.\n'
  exit 0
}
require_command curl
require_output "$FUNCTION_APP_URL" function_app_url
init_response_file
request "$FUNCTION_APP_URL/api/hello?name=Azure"
expect_status 401
access_token
request --header "Authorization: Be""arer $ACCESS_TOKEN" "$FUNCTION_APP_URL/api/hello?name=Azure"
expect_status 200
[ "$(cat "$RESPONSE_FILE")" = 'Hello, Azure!' ] || die "Unexpected authenticated hello response."
request --request POST --header "Authorization: Be""arer $ACCESS_TOKEN" \
  --header 'Content-Type: application/json' --data '{"name":"World"}' \
  "$FUNCTION_APP_URL/api/hello"
expect_status 200
[ "$(cat "$RESPONSE_FILE")" = 'Hello, World!' ] || die "Unexpected authenticated POST response."
printf 'Easy Auth verified (401 without token, 200 for GET and POST with token).\n'
