#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

: "${ACME_ENV:=staging}"
: "${TLS_NAMESPACE:=workshop-tls}"
: "${TLS_GATEWAY_NAME:=tls-workshop}"
: "${CERTIFICATE_NAME:=workshop-tls}"

require_common_commands
require_command curl
require_command dig
require_command grep
validate_configuration
load_terraform_outputs
require_scenario_outputs

[ -n "${ACME_EMAIL:-}" ] || die "Set ACME_EMAIL to the Let's Encrypt account email address."
[ -n "${DNS_NAME:-}" ] || die "Set DNS_NAME to the public hostname for the TLS workshop."

case "$ACME_EMAIL" in
  *@*.*) ;;
  *) die "ACME_EMAIL is not a valid email address: ${ACME_EMAIL}" ;;
esac
case "$DNS_NAME" in
  ''|*[!a-z0-9.-]*|.*|*.) die "DNS_NAME must be a lowercase DNS hostname: ${DNS_NAME}" ;;
esac

case "$ACME_ENV" in
  staging)
    ACME_SERVER=https://acme-staging-v02.api.letsencrypt.org/directory
    CLUSTER_ISSUER_NAME=letsencrypt-staging
    ;;
  production)
    [ "${CONFIRM_PRODUCTION_CERTIFICATE:-}" = "issue-production-certificate" ] \
      || die "Set CONFIRM_PRODUCTION_CERTIFICATE=issue-production-certificate to use Let's Encrypt production."
    ACME_SERVER=https://acme-v02.api.letsencrypt.org/directory
    CLUSTER_ISSUER_NAME=letsencrypt-production
    ;;
  *)
    die "ACME_ENV must be staging or production."
    ;;
esac

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
  kubectl get deployment cert-manager --namespace cert-manager >/dev/null

  TLS_GATEWAY_ADDRESS=$(kubectl get gateway "$TLS_GATEWAY_NAME" \
    --namespace "$TLS_NAMESPACE" \
    --output jsonpath='{.status.addresses[0].value}')
  [ -n "$TLS_GATEWAY_ADDRESS" ] || die "The TLS Gateway does not have an address."

  case "$TLS_GATEWAY_ADDRESS" in
    *[!0-9.]*) die "Expected an IPv4 Gateway address, found: ${TLS_GATEWAY_ADDRESS}" ;;
  esac
  dig +short A "$DNS_NAME" | grep --fixed-strings --line-regexp "$TLS_GATEWAY_ADDRESS" >/dev/null \
    || die "DNS ${DNS_NAME} does not resolve to Gateway address ${TLS_GATEWAY_ADDRESS}."
fi

if [ "$DRY_RUN" = "true" ]; then
  log "DRY RUN: apply ClusterIssuer ${CLUSTER_ISSUER_NAME}, Certificate ${CERTIFICATE_NAME}, HTTPS Gateway, and HTTPRoute for ${DNS_NAME}."
else
  kubectl apply --filename - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${CLUSTER_ISSUER_NAME}
  labels:
    app.kubernetes.io/part-of: azure-kubernetes-playground
spec:
  acme:
    email: ${ACME_EMAIL}
    server: ${ACME_SERVER}
    privateKeySecretRef:
      name: ${CLUSTER_ISSUER_NAME}-account-key
    solvers:
      - http01:
          gatewayHTTPRoute:
            parentRefs:
              - name: ${TLS_GATEWAY_NAME}
                namespace: ${TLS_NAMESPACE}
                kind: Gateway
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CERTIFICATE_NAME}
  namespace: ${TLS_NAMESPACE}
  labels:
    app.kubernetes.io/part-of: azure-kubernetes-playground
spec:
  secretName: ${CERTIFICATE_NAME}
  dnsNames:
    - ${DNS_NAME}
  issuerRef:
    name: ${CLUSTER_ISSUER_NAME}
    kind: ClusterIssuer
EOF

  kubectl apply --filename - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ${TLS_GATEWAY_NAME}
  namespace: ${TLS_NAMESPACE}
  labels:
    app.kubernetes.io/name: ${TLS_GATEWAY_NAME}
    app.kubernetes.io/part-of: azure-kubernetes-playground
spec:
  gatewayClassName: ${GATEWAY_CLASS_NAME}
  listeners:
    - name: http
      hostname: ${DNS_NAME}
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
    - name: https
      hostname: ${DNS_NAME}
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
          - name: ${CERTIFICATE_NAME}
      allowedRoutes:
        namespaces:
          from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: tls-sample
  namespace: ${TLS_NAMESPACE}
  labels:
    app.kubernetes.io/name: tls-sample
    app.kubernetes.io/part-of: azure-kubernetes-playground
spec:
  parentRefs:
    - name: ${TLS_GATEWAY_NAME}
      sectionName: http
    - name: ${TLS_GATEWAY_NAME}
      sectionName: https
  hostnames:
    - ${DNS_NAME}
  rules:
    - backendRefs:
        - name: tls-sample
          port: 80
EOF

  kubectl wait \
    --for=condition=Ready \
    "certificate/${CERTIFICATE_NAME}" \
    --namespace "$TLS_NAMESPACE" \
    --timeout="$HELM_WAIT_TIMEOUT"
  kubectl wait \
    --for=condition=Programmed \
    "gateway/${TLS_GATEWAY_NAME}" \
    --namespace "$TLS_NAMESPACE" \
    --timeout="$KUBECTL_WAIT_TIMEOUT"

  if [ "$ACME_ENV" = "staging" ]; then
    curl --fail --insecure --silent --show-error "https://${DNS_NAME}/" >/dev/null
  else
    curl --fail --silent --show-error "https://${DNS_NAME}/" >/dev/null
  fi
fi

log "Certificate workshop completed with Let's Encrypt ${ACME_ENV}."
log "HTTPS URL: https://${DNS_NAME}/"
