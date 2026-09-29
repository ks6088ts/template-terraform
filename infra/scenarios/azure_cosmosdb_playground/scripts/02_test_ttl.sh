#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
require_tools
load_outputs
get_tokens
id=cosmos-playground-ttl
doc=$(jq -nc --arg id "$id" --arg tenant "$PLAYGROUND_TENANT" --arg tag "$PLAYGROUND_TAG" \
  '{id:$id,tenantId:$tenant,playgroundTag:$tag,content:"Expires via item-level TTL",ttl:30}')
put_document "$doc"
read_document "$id"
expect_status 200
printf '%s' "$HTTP_BODY" | jq -e '.ttl == 30' >/dev/null || die "TTL not stored"
attempt=0
while [ "$attempt" -lt "$POLL_ATTEMPTS" ]; do
  read_document "$id"
  if [ "$HTTP_STATUS" = 404 ]; then
    log "Item TTL expiry verified."
    exit 0
  fi
  attempt=$((attempt + 1))
  [ "$attempt" -lt "$POLL_ATTEMPTS" ] && sleep "$POLL_INTERVAL"
done
die "TTL item did not expire within $POLL_ATTEMPTS checks; increase POLL_ATTEMPTS/POLL_INTERVAL"
