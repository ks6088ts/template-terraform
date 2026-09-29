#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
require_tools
load_outputs
get_tokens
get_foundry_token
cosmos_request GET dbs dbs "$DB_PATH"
expect_status 200
cosmos_request GET colls colls "$COLL_PATH"
expect_status 200
log "Cosmos database and container are reachable; both AAD tokens acquired (not displayed)."
