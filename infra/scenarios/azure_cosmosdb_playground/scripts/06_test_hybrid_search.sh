#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
parse_options "$@"
require_tools
load_outputs
get_tokens
verbose "Running the hybrid search lab."
seed_documents
embed "Find documents about vector search"
query=$(tagged_query \
  'SELECT TOP 3 c.id, c.content FROM c WHERE c.tenantId = @tenant AND c.playgroundTag = @tag ORDER BY RANK RRF(VectorDistance(c.embedding, @vector), FullTextScore(c.content, @term))' \
  "$(jq -nc --argjson vector "$EMBEDDING" --arg term "vector" \
    '[{name:"@vector",value:$vector},{name:"@term",value:$term}]')")
wait_query_documents "$query"
printf '%s' "$HTTP_BODY" | jq -r '.Documents[] | "\(.id): \(.content)"'
