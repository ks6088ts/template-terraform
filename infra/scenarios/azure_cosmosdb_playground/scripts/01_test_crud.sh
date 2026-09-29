#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
parse_options "$@"
require_tools
load_outputs
get_tokens
id=cosmos-playground-crud
verbose "Running CRUD validation for tagged document: $id"
doc=$(jq -nc --arg id "$id" --arg tenant "$PLAYGROUND_TENANT" --arg tag "$PLAYGROUND_TAG" \
  '{id:$id,tenantId:$tenant,playgroundTag:$tag,content:"CRUD created"}')
put_document "$doc"
verbose "Reading the newly created document."
read_document "$id"
expect_status 200
printf '%s' "$HTTP_BODY" | jq -e '.content == "CRUD created"' >/dev/null || die "Create/read mismatch"
updated=$(printf '%s' "$doc" | jq -c '.content = "CRUD updated"')
verbose "Updating and querying the document."
put_document "$updated"
query=$(tagged_query 'SELECT * FROM c WHERE c.tenantId = @tenant AND c.playgroundTag = @tag AND c.id = @id AND c.content = "CRUD updated"' \
  "$(jq -nc --arg id "$id" '[{name:"@id",value:$id}]')")
wait_query_documents "$query"
printf '%s' "$HTTP_BODY" | jq -e --arg id "$id" \
  'any(.Documents[]?; .id == $id and .content == "CRUD updated")' >/dev/null || die "Update/query mismatch"
delete_document "$id"
verbose "Confirming the deleted document returns HTTP 404."
read_document "$id"
expect_status 404
log "CRUD create/read/update/query/delete verified."
