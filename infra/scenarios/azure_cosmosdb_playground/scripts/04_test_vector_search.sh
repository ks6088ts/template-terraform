#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
parse_options "$@"
require_tools
load_outputs
get_tokens
verbose "Running the vector search lab."
seed_documents
embed "How does Cosmos DB store documents?"
query=$(tagged_query \
  'SELECT TOP 3 c.id, c.content, VectorDistance(c.embedding, @vector) AS distance FROM c WHERE c.tenantId = @tenant AND c.playgroundTag = @tag ORDER BY VectorDistance(c.embedding, @vector)' \
  "$(jq -nc --argjson vector "$EMBEDDING" '[{name:"@vector",value:$vector}]')")
wait_query_documents "$query"
printf '%s' "$HTTP_BODY" | jq -r '.Documents[] | "\(.id): \(.content)"'
