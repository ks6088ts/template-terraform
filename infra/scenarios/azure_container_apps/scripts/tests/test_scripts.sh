#!/bin/sh

set -eu

TEST_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
SCRIPT_DIR=$(CDPATH='' cd "${TEST_DIR}/.." && pwd)
umask 077
FIXTURE=$(mktemp -d "${TMPDIR:-/tmp}/container-apps-tests.XXXXXX")
mkdir "$FIXTURE/bin"
trap 'rm -rf "$FIXTURE"' 0
trap 'exit 1' 1 2 3 15
export FIXTURE
PATH="$FIXTURE/bin:$PATH"
export PATH

cat >"$FIXTURE/bin/terraform" <<'EOF'
#!/bin/sh
[ "$2" = output ] && [ "$3" = -json ] || exit 1
case "${MOCK_CASE:-authenticated}" in
  authenticated)
    auth='"api://container-app"'
    insights='"insights-app-id"'
    ;;
  *)
    auth=null
    insights=null
    ;;
esac
cat <<JSON
{"resource_group_name":{"value":"rg-example"},"acr_id":{"value":"/subscriptions/sub-123/resourceGroups/rg-example/providers/Microsoft.ContainerRegistry/registries/crexample"},"acr_name":{"value":"crexample"},"acr_login_server":{"value":"crexample.azurecr.io"},"container_app_url":{"value":"https://app.example.test"},"container_app_authentication_identifier_uri":{"value":${auth}},"application_insights_app_id":{"value":${insights}}}
JSON
EOF

cat >"$FIXTURE/bin/az" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$FIXTURE/az.calls"
case "$*" in
  "account get-access-token --subscription sub-123 --resource api://container-app --query accessToken --output tsv")
    printf 'test-token\n'
    ;;
  "cloud show --query endpoints.appInsightsResourceId --output tsv")
    printf 'https://api.applicationinsights.io\n'
    ;;
  *"rest --method post"*"--url https://api.applicationinsights.io/v1/apps/insights-app-id/query"*"--resource https://api.applicationinsights.io"*"--subscription sub-123"*)
    count=0
    [ ! -f "$FIXTURE/telemetry.count" ] || count=$(cat "$FIXTURE/telemetry.count")
    count=$((count + 1))
    printf '%s\n' "$count" >"$FIXTURE/telemetry.count"
    if [ "$count" -lt 2 ]; then
      printf '{"tables":[{"rows":[]}]}\n'
    else
      printf '{"tables":[{"rows":[["GET /health"]]}]}\n'
    fi
    ;;
  *)
    exit 1
    ;;
esac
EOF

cat >"$FIXTURE/bin/curl" <<'EOF'
#!/bin/sh
body_file=''
url=''
auth=no
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output)
      body_file=$2
      shift
      ;;
    --header)
      [ "$2" != "Authorization: Bearer test-token" ] || auth=yes
      shift
      ;;
    https://*) url=$1 ;;
    --write-out) shift ;;
  esac
  shift
done

case "${MOCK_CASE:-authenticated}" in
  authenticated) [ "$auth" = yes ] || exit 1 ;;
  *) [ "$auth" = no ] || exit 1 ;;
esac

case "$url" in
  */health) body='{"status":"healthy"}' ;;
  */mcp)
    case "${MOCK_CASE:-authenticated}" in
      sse) body='data: {"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"list_tasks"}]}}' ;;
      bad_mcp) body='{"jsonrpc":"2.0","id":1,"result":{}}' ;;
      *) body='{"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"list_tasks"}]}}' ;;
    esac
    ;;
  *) exit 1 ;;
esac

printf '%s\n' "$body" >"$body_file"
printf '200'
EOF

cat >"$FIXTURE/bin/sleep" <<'EOF'
#!/bin/sh
:
EOF

chmod +x "$FIXTURE/bin/"*

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

expect_failure() {
  if "$@" >"$FIXTURE/stdout" 2>"$FIXTURE/stderr"; then
    fail "Expected failure: $*"
  fi
}

TELEMETRY_MAX_ATTEMPTS=3 TELEMETRY_RETRY_SECONDS=0 \
  "$SCRIPT_DIR/verify_deployment.sh" --verbose >"$FIXTURE/stdout" 2>"$FIXTURE/stderr" \
  || fail "Authenticated verification failed"
grep -q 'Application Insights telemetry found on attempt 2' "$FIXTURE/stdout" \
  || fail "Telemetry retry was not verified"
if grep -q 'test-token' "$FIXTURE/stdout" "$FIXTURE/stderr"; then
  fail "Bearer token was written to verification output"
fi
grep -q -- '--subscription sub-123' "$FIXTURE/az.calls" \
  || fail "Azure operations were not scoped to the Terraform subscription"
grep -q "requests | where timestamp >= datetime(" "$FIXTURE/az.calls" \
  || fail "Telemetry query was not scoped to the verification window"

MOCK_CASE=anonymous
export MOCK_CASE
"$SCRIPT_DIR/verify_deployment.sh" >"$FIXTURE/stdout" 2>"$FIXTURE/stderr" \
  || fail "Anonymous verification failed"

MOCK_CASE=sse
"$SCRIPT_DIR/verify_deployment.sh" --verbose >"$FIXTURE/stdout" 2>"$FIXTURE/stderr" \
  || fail "SSE verification failed"
grep -q 'MCP response format: text/event-stream' "$FIXTURE/stdout" \
  || fail "SSE response format was not detected"

MOCK_CASE=bad_mcp
expect_failure "$SCRIPT_DIR/verify_deployment.sh"
grep -q 'did not return a tools/list result' "$FIXTURE/stderr" \
  || fail "Invalid MCP response did not produce an actionable error"

expect_failure "$SCRIPT_DIR/verify_deployment.sh" --unknown
