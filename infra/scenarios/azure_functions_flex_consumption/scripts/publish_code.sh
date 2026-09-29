#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_common.sh"

[ "$#" -eq 0 ] || die "Usage: publish_code.sh"
load_outputs
require_command func
require_output "$FUNCTION_APP_URL" function_app_url

# Stage only the files required for publishing; local.settings.json never enters the package.
umask 077
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/flex-publish.XXXXXX") ||
  die "Cannot create publish staging directory."
trap 'rm -rf "$STAGE"' 0
trap 'exit 1' 1 2 3 15
for file in function_app.py requirements.txt host.json; do
  [ -f "$SCENARIO_DIR/src/$file" ] || die "Missing source file: $file."
  cp "$SCENARIO_DIR/src/$file" "$STAGE/$file"
done
(cd "$STAGE" && func azure functionapp publish "$FUNCTION_APP_NAME" \
  --subscription "$SUBSCRIPTION_ID" --build remote) ||
  die "Core Tools publish failed."
printf 'Published %s to subscription %s.\n' "$FUNCTION_APP_NAME" "$SUBSCRIPTION_ID"
