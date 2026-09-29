#!/bin/sh

set -eu
SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
[ "$#" -eq 0 ] || { printf 'Usage: run_all.sh\n' >&2; exit 1; }

# Deliberately does not publish code or modify cloud resources.
for check in 00_validate_prerequisites 01_test_entra_http 02_test_function_key \
  03_test_storage_identity 04_test_timer 05_test_http_telemetry; do
  "$SCRIPT_DIR/$check.sh"
done
