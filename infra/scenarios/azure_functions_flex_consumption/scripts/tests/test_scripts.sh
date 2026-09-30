#!/bin/sh

set -eu
TEST_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
SCRIPT_DIR=$(CDPATH='' cd "$TEST_DIR/.." && pwd)
umask 077
FIXTURE=$(mktemp -d "${TMPDIR:-/tmp}/flex-tests.XXXXXX")
mkdir "$FIXTURE/bin"
trap 'rm -rf "$FIXTURE"' 0
trap 'exit 1' 1 2 3 15
export FIXTURE
PATH="$FIXTURE/bin:$PATH"
export PATH

cat > "$FIXTURE/bin/terraform" <<'EOF'
#!/bin/sh
[ "$2" = output ] && [ "$3" = -json ] || exit 1
cat <<'JSON'
{"subscription_id":{"value":"sub-123"},"resource_group_name":{"value":"rg-example"},"function_app_name":{"value":"func-example"},"function_app_id":{"value":"/subscriptions/sub-123/resourceGroups/rg-example/providers/Microsoft.Web/sites/func-example"},"function_app_url":{"value":"https://func.example.test"},"function_app_authentication_identifier_uri":{"value":"api://app-123"},"storage_account_name":{"value":"stexample"},"deployment_container_name":{"value":"deployments"},"log_analytics_workspace_customer_id":{"value":"workspace-123"},"application_insights_app_id":{"value":"insights-123"},"timer_schedule":{"value":"0 * * * * *"}}
JSON
EOF
cat > "$FIXTURE/bin/az" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FIXTURE/az.calls"
case "$*" in
  "account show --query id --output tsv") ;;
  "cloud show --query endpoints.appInsightsResourceId --output tsv") ;;
  *" --subscription sub-123 "*) ;;
  *) exit 1 ;;
esac
case "$*" in
  *"account show"*)
    if [ "${MOCK_CASE:-}" = wrong_subscription ]; then
      printf 'different-subscription\n'
    else
      printf 'sub-123\n'
    fi ;;
  *"get-access-token"*) printf 'test-token\n' ;;
  *"keys list"*) printf 'test-key\n' ;;
  *"function show"*)
    if [ "${MOCK_CASE:-}" = bad_schedule ]; then
      printf '0 15 * * * *\n'
    else
      printf '%%TIMER_SCHEDULE%%\n'
    fi ;;
  *"appsettings list"*)
    if [ "${MOCK_CASE:-}" = bad_setting ]; then
      printf '0 15 * * * *\n'
    else
      printf '0 * * * * *\n'
    fi ;;
  *"cloud show"*) printf 'https://api.applicationinsights.io\n' ;;
  *"rest"*)
    case "$*" in
      *"--method post"*"--url https://api.applicationinsights.io/v1/apps/insights-123/query"*"--resource https://api.applicationinsights.io"*"\"query\":"*"take 1"*) ;;
      *) exit 1 ;;
    esac
    case "$*" in
      *"timestamp >= "*"timestamp <= datetime("*|*"timestamp between ("*) ;;
      *) exit 1 ;;
    esac
    if [ "${MOCK_CASE:-}" = delayed_telemetry ]; then
      count=0
      [ ! -f "$FIXTURE/telemetry.count" ] || count=$(cat "$FIXTURE/telemetry.count")
      count=$((count + 1))
      printf '%s\n' "$count" > "$FIXTURE/telemetry.count"
      if [ "$count" -lt 3 ]; then
        printf '{"tables":[{"rows":[]}]}\n'
      else
        printf '{"tables":[{"rows":[["hit"]]}]}\n'
      fi
    elif [ "${MOCK_CASE:-}" = no_telemetry ]; then
      printf '{"tables":[{"rows":[]}]}\n'
    else
      printf '{"tables":[{"rows":[["hit"]]}]}\n'
    fi ;;
  *) exit 1 ;;
esac
EOF
cat > "$FIXTURE/bin/curl" <<'EOF'
#!/bin/sh
body_file=''
url=''
auth=no
key=no
method=GET
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output) body_file=$2; shift ;;
    --request) method=$2; shift ;;
    --data) [ "$2" = '{"name":"World"}' ] || exit 1; shift ;;
    --header)
      case "$2" in
        "Authorization: "*"test-token") auth=yes ;;
        "x-functions-key: test-key") key=yes ;;
      esac
      shift ;;
    https://*) url=$1 ;;
    --write-out|--max-time) shift ;;
  esac
  shift
done
case "$url" in
  */api/hello-key*)
    if [ "$key" = yes ]; then status=200; body='Hello, Azure!'
    else status=401; body='Unauthorized'; fi ;;
  */api/hello*)
    if [ "$auth" = yes ]; then
      status=200
      if [ "$method" = POST ]; then
        body='Hello, World!'
      else
        case "$url" in
          *'name=Telemetry') body='Hello, Telemetry!' ;;
          *) body='Hello, Azure!' ;;
        esac
      fi
    else status=401; body='Unauthorized'; fi ;;
  */api/storage-check)
    if [ "$auth" = yes ]; then
      status=200
      if [ "${MOCK_CASE:-}" = storage_unavailable ]; then
        status=503
        body='sensitive-server-details'
      elif [ "${MOCK_CASE:-}" = bad_container ]; then
        body='{"status":"ok","container":"wrong"}'
      elif [ "${MOCK_CASE:-}" = extra_field ]; then
        body='{"status":"ok","container":"deployments","unexpected":true}'
      else
        body='{"status":"ok","container":"deployments"}'
      fi
    else status=401; body='Unauthorized'; fi ;;
  *) exit 1 ;;
esac
if [ "${MOCK_CASE:-}" = bad_auth ] && [ "$url" = 'https://func.example.test/api/hello?name=Azure' ]; then
  status=200
fi
if [ "${MOCK_CASE:-}" = bad_post ] && [ "$method" = POST ]; then
  status=500
fi
if [ "${MOCK_CASE:-}" = bad_key ] && [ "$url" = 'https://func.example.test/api/hello-key?name=Azure' ]; then
  status=200
fi
printf '%s' "$body" > "$body_file"
printf '%s' "$status"
EOF
cat > "$FIXTURE/bin/func" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" > "$FIXTURE/func.calls"
ls -a > "$FIXTURE/published.files"
case "$*" in
  "azure functionapp publish func-example --subscription sub-123 --build remote --python") ;;
  *) exit 1 ;;
esac
EOF
cat > "$FIXTURE/bin/sleep" <<'EOF'
#!/bin/sh
:
EOF
chmod +x "$FIXTURE/bin/"*

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

expect_failure() {
  if "$@" > "$FIXTURE/stdout" 2> "$FIXTURE/stderr"; then
    fail "Expected failure: $*"
  fi
}

"$SCRIPT_DIR/publish_code.sh" > "$FIXTURE/stdout" || fail 'Publish failed'
grep -q '^function_app.py$' "$FIXTURE/published.files" || fail 'Function source not staged'
if grep -q 'local.settings.json' "$FIXTURE/published.files"; then
  fail 'Local settings were staged'
fi

"$SCRIPT_DIR/00_validate_prerequisites.sh" > "$FIXTURE/stdout" || fail 'Prerequisites verification failed'
"$SCRIPT_DIR/01_test_entra_http.sh" > "$FIXTURE/stdout" || fail 'Easy Auth verification failed'
"$SCRIPT_DIR/02_test_function_key.sh" > "$FIXTURE/stdout" || fail 'Key verification failed'
"$SCRIPT_DIR/03_test_storage_identity.sh" > "$FIXTURE/stdout" || fail 'Storage verification failed'
"$SCRIPT_DIR/04_test_timer.sh" > "$FIXTURE/stdout" || fail 'Timer verification failed'
"$SCRIPT_DIR/05_test_http_telemetry.sh" > "$FIXTURE/stdout" || fail 'Telemetry verification failed'
grep -q -- '--url https://api.applicationinsights.io/v1/apps/insights-123/query' "$FIXTURE/az.calls" ||
  fail 'Telemetry not scoped to app ID'
grep -q -- '--resource https://api.applicationinsights.io' "$FIXTURE/az.calls" ||
  fail 'Telemetry token not scoped to the Application Insights API'
grep -q -- '--subscription sub-123' "$FIXTURE/az.calls" || fail 'Azure operations not scoped to subscription'
grep -q "dependencies | where timestamp >=" "$FIXTURE/az.calls" || fail 'OpenTelemetry dependencies not queried'
grep -q "(datetime(.*) - 5s)" "$FIXTURE/az.calls" || fail 'OpenTelemetry query lacks clock-skew tolerance'
grep -q "timestamp <= datetime(" "$FIXTURE/az.calls" || fail 'Telemetry query lacks a concrete upper time bound'
grep -q "name == 'flex-otel-check'" "$FIXTURE/az.calls" || fail 'Named OpenTelemetry span not queried'
grep -q 'datetime(' "$FIXTURE/az.calls" || fail 'OpenTelemetry span not scoped to fresh probe'

MOCK_CASE=delayed_telemetry
export MOCK_CASE
"$SCRIPT_DIR/04_test_timer.sh" > "$FIXTURE/stdout" || fail 'Timer telemetry retry failed'
rm -f "$FIXTURE/telemetry.count"
"$SCRIPT_DIR/05_test_http_telemetry.sh" > "$FIXTURE/stdout" || fail 'OpenTelemetry span retry failed'
unset MOCK_CASE

MOCK_CASE=wrong_subscription
export MOCK_CASE
rm -f "$FIXTURE/func.calls"
for script in 00_validate_prerequisites 01_test_entra_http 02_test_function_key \
  03_test_storage_identity 04_test_timer 05_test_http_telemetry publish_code; do
  expect_failure "$SCRIPT_DIR/$script.sh"
done
[ ! -e "$FIXTURE/func.calls" ] || fail 'Publish must not run for a wrong active subscription'
unset MOCK_CASE

MOCK_CASE=bad_auth
export MOCK_CASE
expect_failure "$SCRIPT_DIR/01_test_entra_http.sh"
MOCK_CASE=bad_post
export MOCK_CASE
expect_failure "$SCRIPT_DIR/01_test_entra_http.sh"
MOCK_CASE=bad_container
export MOCK_CASE
expect_failure "$SCRIPT_DIR/03_test_storage_identity.sh"
MOCK_CASE=extra_field
export MOCK_CASE
expect_failure "$SCRIPT_DIR/03_test_storage_identity.sh"
MOCK_CASE=storage_unavailable
export MOCK_CASE
expect_failure "$SCRIPT_DIR/03_test_storage_identity.sh"
grep -q 'managed identity.*RBAC.*retry' "$FIXTURE/stderr" ||
  fail '503 should explain managed identity RBAC propagation'
if grep -q 'sensitive-server-details' "$FIXTURE/stderr" "$FIXTURE/stdout"; then
  fail 'Storage response body must not be logged'
fi
MOCK_CASE=bad_key
export MOCK_CASE
expect_failure "$SCRIPT_DIR/02_test_function_key.sh"
MOCK_CASE=bad_schedule
export MOCK_CASE
expect_failure "$SCRIPT_DIR/04_test_timer.sh"
MOCK_CASE=bad_setting
export MOCK_CASE
expect_failure "$SCRIPT_DIR/04_test_timer.sh"
MOCK_CASE=no_telemetry
export MOCK_CASE
expect_failure "$SCRIPT_DIR/04_test_timer.sh"
grep -q 'published.*next scheduled timer run.*ingestion' "$FIXTURE/stderr" ||
  fail 'Timer failure should explain publish, next run and ingestion delay'
expect_failure "$SCRIPT_DIR/05_test_http_telemetry.sh"
unset MOCK_CASE

rm -f "$FIXTURE/func.calls"
"$SCRIPT_DIR/run_all.sh" > "$FIXTURE/stdout" || fail 'Read-only check suite failed'
[ ! -e "$FIXTURE/func.calls" ] || fail 'run_all published code'
printf 'All offline script checks passed.\n'
