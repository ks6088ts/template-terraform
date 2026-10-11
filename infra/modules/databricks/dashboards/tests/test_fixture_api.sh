#!/bin/sh

set -eu

for tool in terraform python3 curl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '%s is required for the local Databricks API fixture tests.\n' "$tool" >&2
    exit 1
  fi
done

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/../../../../.." && pwd)
work_dir=$(mktemp -d)
server_pid=

cleanup() {
  if [ -n "$server_pid" ] && kill -0 "$server_pid" 2>/dev/null; then
    kill "$server_pid"
  fi
  find "$work_dir" -depth -delete
}

trap cleanup 0
trap 'exit 1' 1 2 3 15

python3 -u -m http.server 0 --bind 127.0.0.1 \
  --directory "$script_dir/fixtures" >"$work_dir/server.log" 2>&1 &
server_pid=$!

attempt=0
port=
while [ "$attempt" -lt 50 ]; do
  if ! kill -0 "$server_pid" 2>/dev/null; then
    cat "$work_dir/server.log" >&2
    printf 'The local Databricks API fixture server exited unexpectedly.\n' >&2
    exit 1
  fi
  port=$(sed -n 's/.* port \([0-9][0-9]*\) .*/\1/p' "$work_dir/server.log")
  if [ -n "$port" ]; then
    break
  fi
  attempt=$((attempt + 1))
  sleep 0.1
done

if [ -z "$port" ]; then
  cat "$work_dir/server.log" >&2
  printf 'Timed out waiting for the local Databricks API fixture server.\n' >&2
  exit 1
fi

export DATABRICKS_HOST="http://127.0.0.1:$port"
unset DATABRICKS_ACCOUNT_ID DATABRICKS_WORKSPACE_ID DATABRICKS_AZURE_RESOURCE_ID DATABRICKS_CONFIG_PROFILE
curl --fail --silent --show-error --max-time 5 --noproxy '*' \
  "$DATABRICKS_HOST/api/2.0/lakeview/dashboards" >"$work_dir/response.json"

for root in infra/modules/databricks/dashboards infra/scenarios/databricks_dashboards; do
  TF_DATA_DIR="$work_dir/$(printf '%s' "$root" | tr '/' '_')"
  export TF_DATA_DIR
  printf 'Testing %s against the loopback-only Databricks API fixture\n' "$root"
  if [ "$root" = infra/scenarios/databricks_dashboards ]; then
    terraform -chdir="$repo_root/$root" init -backend=false -lockfile=readonly -input=false
  else
    terraform -chdir="$repo_root/$root" init -backend=false -input=false
  fi
  terraform -chdir="$repo_root/$root" validate
  terraform -chdir="$repo_root/$root" test -test-directory=tests/fixture-api \
    -filter="tests/fixture-api/$(basename "$root").tftest.hcl"
done
