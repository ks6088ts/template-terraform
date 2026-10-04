#!/bin/bash
set -euo pipefail

log() {
  printf 'PRIVATE_BLOB_CHECK %s %s\n' "$(date -u +%FT%TZ)" "$*"
}

trap 'log "FAIL unexpected_error line=$LINENO"; exit 1' ERR

if [ "$#" -ne 2 ]; then
  log "FAIL usage: validate-private-blob <blob-host> <private-endpoint-ip>"
  exit 1
fi

host="$1"
expected_ip="$2"
log "START host=$host expected_ip=$expected_ip"

for tool in getent awk curl sleep; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    log "FAIL missing_tool=$tool"
    exit 1
  fi
done

for ((attempt = 1; attempt <= 12; attempt++)); do
  log "ATTEMPT number=$attempt"
  if addresses="$(getent ahostsv4 "$host")"; then
    resolved_ips="$(printf '%s\n' "$addresses" | awk '!seen[$1]++ {print $1}')"
    if [ "$resolved_ips" = "$expected_ip" ]; then
      log "DNS_PASS ip=$resolved_ips"
      if response="$(curl --noproxy '*' -sS --connect-timeout 5 --max-time 20 \
        -o /dev/null -w '%{remote_ip} %{http_code}' "https://$host/?comp=list")"; then
        if [[ "$response" =~ ^([^[:space:]]+)[[:space:]]([1-5][0-9][0-9])$ ]]; then
          remote_ip="${BASH_REMATCH[1]}"
          http_code="${BASH_REMATCH[2]}"
          if [ "$remote_ip" = "$expected_ip" ]; then
            log "HTTPS_PASS remote_ip=$remote_ip http=$http_code tls=verified"
            log "PASS scope=private_dns_tcp_tls_http"
            exit 0
          fi
        fi
        log "RETRY https_result=$response expected_ip=$expected_ip"
      else
        log "RETRY https_connection_failed"
      fi
    else
      log "RETRY dns_ips=$resolved_ips expected_ip=$expected_ip"
    fi
  else
    log "RETRY dns_resolution_failed"
  fi

  if [ "$attempt" -lt 12 ]; then
    sleep 10
  fi
done

log "FAIL attempts=12 scope=private_dns_tcp_tls_http"
exit 1
