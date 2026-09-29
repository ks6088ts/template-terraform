#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/_common.sh"
parse_options "$@"

run_script() {
  if [ "$VERBOSE" = true ]; then
    sh "$1" --verbose
  else
    sh "$1"
  fi
}

verbose "Running playground steps 00 through 07."
for step in 00_validate_prerequisites 01_test_crud 02_test_ttl 03_test_change_feed 04_test_vector_search 05_test_full_text 06_test_hybrid_search 07_test_rag; do
  printf '\n== %s ==\n' "$step"
  if run_script "$SCRIPT_DIR/$step.sh"; then
    :
  else
    status=$?
    if [ "${CLEANUP_AFTER_RUN:-false}" = true ]; then
      verbose "A step failed; attempting tagged data cleanup."
      run_script "$SCRIPT_DIR/08_cleanup.sh" || printf '%s\n' "Warning: tagged data cleanup also failed." >&2
    fi
    exit "$status"
  fi
done
if [ "${CLEANUP_AFTER_RUN:-false}" = true ]; then
  verbose "All lab steps passed; cleaning up tagged data."
  run_script "$SCRIPT_DIR/08_cleanup.sh"
fi
printf '\nAll playground steps passed.\n'
