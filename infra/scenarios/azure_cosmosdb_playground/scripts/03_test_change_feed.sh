#!/bin/sh
set -eu
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/_common.sh"
require_tools
load_outputs
get_tokens

feed_etag='*'

read_feed() {
  cosmos_request GET docs docs "$DOCS_PATH" \
    --header 'A-IM: Incremental feed' --header "If-None-Match: $feed_etag"
  expect_status 200 304
  if [ "$HTTP_STATUS" = 200 ]; then
    [ -n "$HTTP_ETAG" ] || die "Change feed response has no ETag"
    if [ "$HTTP_ETAG" = "$feed_etag" ] && printf '%s' "$HTTP_BODY" | jq -e \
      '(.Documents // []) | length > 0' >/dev/null; then
      die "Change feed returned documents without advancing its ETag"
    fi
    feed_etag=$HTTP_ETAG
  fi
}

drain_feed() {
  n=0
  while [ "$n" -lt "$POLL_ATTEMPTS" ]; do
    read_feed
    [ "$HTTP_STATUS" = 304 ] && return 0
    n=$((n + 1))
    if [ "$n" -lt "$POLL_ATTEMPTS" ] && printf '%s' "$HTTP_BODY" | jq -e \
      '(.Documents // []) | length == 0' >/dev/null; then
      sleep "$POLL_INTERVAL"
    fi
  done
  die "Change feed baseline did not reach 304 within $POLL_ATTEMPTS pages"
}

wait_for_event() {
  target_id=$1
  target_content=$2
  n=0
  while [ "$n" -lt "$POLL_ATTEMPTS" ]; do
    read_feed
    if [ "$HTTP_STATUS" = 200 ] && printf '%s' "$HTTP_BODY" | jq -e \
      --arg id "$target_id" --arg content "$target_content" --arg tag "$PLAYGROUND_TAG" \
      'any(.Documents[]?; .id == $id and .content == $content and .playgroundTag == $tag)' >/dev/null; then
      return 0
    fi
    n=$((n + 1))
    [ "$n" -lt "$POLL_ATTEMPTS" ] && sleep "$POLL_INTERVAL"
  done
  die "Change feed never showed expected insert/update for $target_id"
}

assert_no_event() {
  excluded_id=$1
  n=0
  while [ "$n" -lt "$POLL_ATTEMPTS" ]; do
    read_feed
    if [ "$HTTP_STATUS" = 200 ] && printf '%s' "$HTTP_BODY" | jq -e \
      --arg id "$excluded_id" 'any(.Documents[]?; .id == $id)' >/dev/null; then
      die "Unexpected delete/TTL event in latest-version change feed for $excluded_id"
    fi
    n=$((n + 1))
    [ "$n" -lt "$POLL_ATTEMPTS" ] && sleep "$POLL_INTERVAL"
  done
}

# Establish a continuation at the tip, rather than mistaking historical writes for new events.
drain_feed
id="cosmos-playground-change-feed-$(jq -nr 'now * 1000000 | floor')"
doc=$(jq -nc --arg id "$id" --arg tenant "$PLAYGROUND_TENANT" --arg tag "$PLAYGROUND_TAG" \
  '{id:$id,tenantId:$tenant,playgroundTag:$tag,content:"Change feed insert"}')
put_document "$doc"
wait_for_event "$id" "Change feed insert"
drain_feed
put_document "$(printf '%s' "$doc" | jq -c '.content = "Change feed update"')"
wait_for_event "$id" "Change feed update"
drain_feed
delete_document "$id"
assert_no_event "$id"
log "Change feed insert and update observed; delete produced no event."

ttl_id="cosmos-playground-feed-ttl-$(jq -nr 'now * 1000000 | floor')"
ttl_doc=$(jq -nc --arg id "$ttl_id" --arg tenant "$PLAYGROUND_TENANT" --arg tag "$PLAYGROUND_TAG" \
  '{id:$id,tenantId:$tenant,playgroundTag:$tag,content:"Change feed TTL insert",ttl:15}')
put_document "$ttl_doc"
wait_for_event "$ttl_id" "Change feed TTL insert"
drain_feed
n=0
while [ "$n" -lt "$POLL_ATTEMPTS" ]; do
  read_document "$ttl_id"
  [ "$HTTP_STATUS" = 404 ] && break
  n=$((n + 1))
  [ "$n" -lt "$POLL_ATTEMPTS" ] && sleep "$POLL_INTERVAL"
done
[ "$HTTP_STATUS" = 404 ] || die "TTL document did not expire within polling limit"
assert_no_event "$ttl_id"
log "TTL expiry verified; latest-version change feed produced no expiration event."
