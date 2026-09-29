#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
parse_options "$@"
verbose "Validating Cosmos DB and Foundry prerequisites."
require_tools
load_outputs
get_tokens
get_foundry_token
verbose "Checking the Cosmos DB database."
cosmos_request GET dbs dbs "$DB_PATH"
expect_status 200
verbose "Checking the Cosmos DB container."
cosmos_request GET colls colls "$COLL_PATH"
expect_status 200
log "Cosmos database and container are reachable; both AAD tokens acquired (not displayed)."
