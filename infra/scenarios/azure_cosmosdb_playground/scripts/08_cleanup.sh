#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
require_tools
load_outputs
get_tokens
query=$(tagged_query 'SELECT c.id FROM c WHERE c.tenantId = @tenant AND c.playgroundTag = @tag')
total=0
round=0
while [ "$round" -lt 100 ]; do
  query_documents "$query"
  ids=$(printf '%s' "$HTTP_BODY" | jq -ec '[.Documents[]?.id]') || die "Cannot list tagged documents"
  count=$(printf '%s' "$ids" | jq 'length')
  [ "$count" -gt 0 ] || break
  i=0
  while [ "$i" -lt "$count" ]; do
    id=$(printf '%s' "$ids" | jq -r --argjson i "$i" '.[$i]')
    delete_document "$id"
    i=$((i + 1))
  done
  total=$((total + count))
  round=$((round + 1))
done
[ "$round" -lt 100 ] || die "Cleanup exceeded 100 batches"
log "Removed $total tagged playground document(s); no other data was touched."
