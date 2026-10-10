#!/bin/sh

set -eu

repository_dir=$(CDPATH='' cd "$(dirname "$0")/../.." && pwd)
fixture=$(mktemp -d)
trap 'find "$fixture" -depth -delete' 0
trap 'exit 1' 1 2 3 15
export fixture

mkdir -p "$fixture/bin" "$fixture/scripts" \
  "$fixture/infra/scenarios/first" "$fixture/infra/scenarios/second" \
  "$fixture/infra/modules/azure/example"
cp "$repository_dir/Makefile" "$fixture/Makefile"
cp "$repository_dir/scripts/update_providers.sh" "$fixture/scripts/update_providers.sh"

cat >"$fixture/bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$fixture/curl.calls"
case "${MOCK_CASE:-success}" in
  http_error) printf 'Registry unavailable\n' >&2; exit 22 ;;
  invalid_json) printf '{invalid'; exit 0 ;;
  no_stable) printf '{"versions":[{"version":"6.0.0"},{"version":"5.99.0-beta.1"}]}'; exit 0 ;;
  downgrade) printf '{"versions":[{"version":"5.0.0"}]}'; exit 0 ;;
esac
case "$*" in
  */hashicorp/azurerm/versions)
    printf '{"versions":[{"version":"6.0.0"},{"version":"5.9.0"},{"version":"5.10.0"},{"version":"5.7.0"},{"version":"5.99.0-beta.1"}]}\n'
    ;;
  */hashicorp/random/versions)
    if [ "${MOCK_CASE:-success}" = late_http_error ]; then
      printf 'Registry unavailable for the second provider\n' >&2
      exit 22
    fi
    printf '{"versions":[{"version":"3.9.2"},{"version":"4.0.0"},{"version":"3.9.1"}]}\n'
    ;;
  *) exit 1 ;;
esac
EOF

cat >"$fixture/bin/tfupdate" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$fixture/tfupdate.calls"
[ "${MOCK_CASE:-success}" != update_error ]
EOF

cat >"$fixture/bin/terraform" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$fixture/terraform.calls"
printf '%s\n' "$TF_DATA_DIR" >>"$fixture/data-dir.calls"
case "$2" in
  init)
    [ "$3" = -backend=false ] && [ "$4" = -upgrade ] && [ "$5" = -input=false ]
    mkdir -p "$TF_DATA_DIR"
    ;;
  validate)
    [ -d "$TF_DATA_DIR" ]
    [ "${MOCK_CASE:-success}" != validation_error ]
    ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$fixture/bin/curl" "$fixture/bin/tfupdate" "$fixture/bin/terraform"
PATH="$fixture/bin:$PATH"
export PATH

cat >"$fixture/infra/scenarios/first/.terraform.lock.hcl" <<'EOF'
provider "registry.terraform.io/hashicorp/azurerm" {
  version     = "5.7.0"
}
provider "registry.terraform.io/hashicorp/random" {
  version     = "3.9.1"
}
EOF
cat >"$fixture/infra/scenarios/second/.terraform.lock.hcl" <<'EOF'
provider "registry.terraform.io/hashicorp/azurerm" {
  version     = "5.9.0"
}
EOF
cp "$fixture/infra/scenarios/second/.terraform.lock.hcl" \
  "$fixture/infra/modules/azure/example/.terraform.lock.hcl"
git -C "$fixture" init -q
git -C "$fixture" add infra

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  if [ -f "$fixture/stdout" ]; then
    cat "$fixture/stdout" >&2
  fi
  if [ -f "$fixture/stderr" ]; then
    cat "$fixture/stderr" >&2
  fi
  exit 1
}

run_update() {
  make --no-print-directory -C "$fixture" update ARM_SUBSCRIPTION_ID= \
    >"$fixture/stdout" 2>"$fixture/stderr"
}

run_update || fail "Bulk update failed"
[ "$(wc -l <"$fixture/curl.calls" | tr -d ' ')" = 2 ] \
  || fail "Provider releases were not fetched exactly once per provider"
grep -q '^provider --recursive --version ~> 5.10.0 hashicorp/azurerm infra/scenarios$' \
  "$fixture/tfupdate.calls" || fail "Scenario constraint did not select the latest stable same-major release"
grep -q '^provider --recursive --version >= 5.10.0, < 6.0.0 hashicorp/azurerm infra/modules$' \
  "$fixture/tfupdate.calls" || fail "Module upper bound was not retained"
grep -q '^provider --recursive --version ~> 3.9.2 hashicorp/random infra/scenarios$' \
  "$fixture/tfupdate.calls" || fail "Pinned provider was not updated"
[ "$(grep -c ' validate$' "$fixture/terraform.calls")" = 3 ] \
  || fail "Not all tracked roots were validated"
while IFS= read -r data_dir; do
  [ ! -d "$data_dir" ] || fail "Temporary Terraform data directory was not cleaned"
done <"$fixture/data-dir.calls"

for MOCK_CASE in http_error late_http_error invalid_json no_stable downgrade; do
  export MOCK_CASE
  rm -f "$fixture/tfupdate.calls" "$fixture/terraform.calls"
  if run_update; then
    fail "Expected failure for $MOCK_CASE"
  fi
  [ ! -f "$fixture/tfupdate.calls" ] && [ ! -f "$fixture/terraform.calls" ] \
    || fail "Configuration was updated despite a Registry failure"
  [ -s "$fixture/stderr" ] || fail "Failure was not reported for $MOCK_CASE"
done

MOCK_CASE=update_error
export MOCK_CASE
if run_update; then
  fail "Expected constraint update failure"
fi
[ ! -f "$fixture/terraform.calls" ] || fail "Lock update ran after constraint update failed"

MOCK_CASE=validation_error
export MOCK_CASE
if run_update; then
  fail "Expected validation failure"
fi
[ "$(grep -c ' validate$' "$fixture/terraform.calls")" = 1 ] \
  || fail "Update did not stop after validation failed"
unset MOCK_CASE

cat >"$fixture/infra/scenarios/second/.terraform.lock.hcl" <<'EOF'
provider "registry.terraform.io/hashicorp/azurerm" {
  version     = "6.0.0"
}
EOF
rm -f "$fixture/tfupdate.calls" "$fixture/terraform.calls"
if run_update; then
  fail "Expected conflicting-major failure"
fi
grep -q 'Conflicting locked major versions' "$fixture/stderr" \
  || fail "Conflicting-major error was not reported"
[ ! -f "$fixture/tfupdate.calls" ] || fail "Constraints changed despite conflicting majors"

if make --no-print-directory -C "$fixture" update TERRAFORM_LOCK_FILE_LIST= ARM_SUBSCRIPTION_ID= \
  >"$fixture/stdout" 2>"$fixture/stderr"; then
  fail "Expected failure with no tracked lock files"
fi
grep -q 'No tracked Terraform lock files' "$fixture/stderr" \
  || fail "Empty-target error was not reported"

printf 'PASS: provider constraint selection, bulk validation, cleanup, and failure handling\n'
