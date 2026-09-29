#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
require_tools
load_outputs
get_tokens
seed_documents
query=$(tagged_query \
  'SELECT TOP 3 c.id, c.content FROM c WHERE c.tenantId = @tenant AND c.playgroundTag = @tag AND FullTextContains(c.content, @term) ORDER BY RANK FullTextScore(c.content, @term)' \
  "$(jq -nc '[{name:"@term",value:"Cosmos"}]')")
wait_query_documents "$query"
printf '%s' "$HTTP_BODY" | jq -r '.Documents[] | "\(.id): \(.content)"'
