#!/bin/bash
set -euo pipefail

test_source="$(cd "$(dirname "$0")" && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -f "$test_dir/getent" "$test_dir/curl" "$test_dir/sleep" "$test_dir/state"; rmdir "$test_dir"' EXIT

for tool in getent curl sleep; do
  cp "$test_source/mock_tools.sh" "$test_dir/$tool"
  chmod +x "$test_dir/$tool"
done
export PATH="$test_dir:$PATH"
export MOCK_STATE="$test_dir/state"
script="$test_source/../validate_private_blob.sh"

for scenario in success http_bad_request retry_success wrong_dns wrong_remote dns_failure empty_dns tls_failure timeout http_zero; do
  export MOCK_CASE="$scenario"
  rm -f "$MOCK_STATE"
  status=0
  output="$(bash "$script" storageaccounttest.blob.core.windows.net 10.1.1.4 2>&1)" || status=$?

  case "$scenario" in
    success|http_bad_request|retry_success)
      if [ "$status" -ne 0 ] || [[ "$output" != *"PASS scope=private_dns_tcp_tls_http"* ]]; then
        printf 'FAIL %s\n%s\n' "$scenario" "$output"
        exit 1
      fi
      if [[ "$output" != *"DNS_PASS ip=10.1.1.4"* || "$output" != *"HTTPS_PASS remote_ip=10.1.1.4"* ]]; then
        printf 'FAIL missing acceptance evidence: %s\n%s\n' "$scenario" "$output"
        exit 1
      fi
      if [ "$scenario" = retry_success ] && [[ "$output" != *"ATTEMPT number=2"* ]]; then
        echo "FAIL retry did not run"
        exit 1
      fi
      ;;
    *)
      if [ "$status" -eq 0 ] || [[ "$output" == *"PASS scope="* || "$output" != *"FAIL attempts=12"* ]]; then
        printf 'FAIL %s\n%s\n' "$scenario" "$output"
        exit 1
      fi
      if [ "$(printf '%s\n' "$output" | grep -c 'ATTEMPT number=')" -ne 12 ]; then
        echo "FAIL incorrect retry limit"
        exit 1
      fi
      ;;
  esac
  printf 'PASS %s\n' "$scenario"
done

if bash "$script" > /dev/null 2>&1; then
  echo "FAIL missing arguments must fail"
  exit 1
fi
echo "PASS missing arguments"
