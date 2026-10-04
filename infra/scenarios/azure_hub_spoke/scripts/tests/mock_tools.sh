#!/bin/bash
set -euo pipefail

case "${0##*/}" in
  getent)
    case "$MOCK_CASE" in
      dns_failure) exit 2 ;;
      empty_dns) exit 0 ;;
      wrong_dns) printf '203.0.113.1 STREAM\n' ;;
      retry_success)
        if [ ! -e "$MOCK_STATE" ]; then
          touch "$MOCK_STATE"
          exit 2
        fi
        printf '10.1.1.4 STREAM\n10.1.1.4 DGRAM\n'
        ;;
      *) printf '10.1.1.4 STREAM\n10.1.1.4 DGRAM\n' ;;
    esac
    ;;
  curl)
    if [[ " $* " != *" --noproxy * "* || " $* " == *" -k "* || " $* " == *" -f "* ]]; then
      echo "Unsafe curl arguments" >&2
      exit 1
    fi
    case "$MOCK_CASE" in
      tls_failure) echo "curl: certificate verification failed" >&2; exit 60 ;;
      timeout) echo "curl: connection timed out" >&2; exit 28 ;;
      wrong_remote) printf '203.0.113.1 403' ;;
      http_zero) printf '10.1.1.4 000' ;;
      http_bad_request) printf '10.1.1.4 400' ;;
      *) printf '10.1.1.4 403' ;;
    esac
    ;;
  sleep) exit 0 ;;
  *) echo "Unknown mock tool" >&2; exit 1 ;;
esac
