#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH='' cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/_common.sh"

TARGET=${1:-}

[ -n "$TARGET" ] || die "Specify a cleanup target: http, monitoring, argocd, workflows, keycloak, open-webui, kubecost, otel-lightweight, otel-demo, cert-manager, tidb, all, or platform."
[ "${CONFIRM_CLEANUP:-}" = "delete-kubernetes-workshop-resources" ] \
  || die "Set CONFIRM_CLEANUP=delete-kubernetes-workshop-resources to clean workshop resources."

require_common_commands
require_command helm
validate_configuration
load_terraform_outputs
require_scenario_outputs

if [ "$DRY_RUN" != "true" ]; then
  require_target_subscription
  require_cluster_context
fi

delete_namespace() {
  NAMESPACE_NAME=$1
  if [ "$DRY_RUN" = "true" ]; then
    print_command kubectl delete namespace "$NAMESPACE_NAME" --ignore-not-found
  elif kubectl get namespace "$NAMESPACE_NAME" >/dev/null 2>&1; then
    kubectl delete namespace "$NAMESPACE_NAME" --wait=true
  else
    log "Namespace already absent: ${NAMESPACE_NAME}"
  fi
}

uninstall_release() {
  RELEASE_NAME=$1
  RELEASE_NAMESPACE=$2
  if [ "$DRY_RUN" = "true" ]; then
    print_command helm uninstall "$RELEASE_NAME" --namespace "$RELEASE_NAMESPACE"
  elif helm status "$RELEASE_NAME" --namespace "$RELEASE_NAMESPACE" >/dev/null 2>&1; then
    helm uninstall "$RELEASE_NAME" --namespace "$RELEASE_NAMESPACE" --wait
  else
    log "Helm release already absent: ${RELEASE_NAMESPACE}/${RELEASE_NAME}"
  fi
}

cleanup_http() {
  delete_namespace workshop-http

  if [ "${CONFIRM_DELETE_ACR_IMAGE:-}" = "delete-workshop-acr-image" ]; then
    run_command az acr repository delete \
      --subscription "$AZURE_SUBSCRIPTION_ID" \
      --name "$ACR_NAME" \
      --repository workshop-kubernetes \
      --yes \
      --output none
  else
    log "Retained ACR repository: ${ACR_LOGIN_SERVER}/workshop-kubernetes"
  fi
}

cleanup_monitoring() {
  uninstall_release kube-prometheus-stack monitoring
  delete_namespace monitoring
  log "Retained Prometheus Operator CRDs."
}

cleanup_argocd() {
  run_command kubectl delete application guestbook \
    --namespace argocd \
    --ignore-not-found \
    --wait=true
  delete_namespace workshop-guestbook
  uninstall_release argocd argocd
  delete_namespace argocd
  log "Retained Argo CD CRDs."
}

cleanup_workflows() {
  delete_namespace workshop-workflows
  uninstall_release argo-workflows argo
  delete_namespace argo
  log "Retained Argo Workflows CRDs."
}

cleanup_keycloak() {
  run_command kubectl delete keycloakrealmimport workshop-realm \
    --namespace keycloak \
    --ignore-not-found \
    --wait=true
  run_command kubectl delete keycloak workshop-keycloak \
    --namespace keycloak \
    --ignore-not-found \
    --wait=true
  delete_namespace keycloak
  log "Retained Keycloak Operator CRDs. Ephemeral workshop database data was deleted."
}

cleanup_open_webui() {
  uninstall_release open-webui open-webui
  if [ "${CONFIRM_DELETE_DATA:-}" = "delete-persistent-workshop-data" ]; then
    delete_namespace open-webui
  else
    log "Retained namespace and Open WebUI PersistentVolumeClaim: open-webui"
  fi
}

cleanup_kubecost() {
  uninstall_release kubecost kubecost
  if [ "${CONFIRM_DELETE_DATA:-}" = "delete-persistent-workshop-data" ]; then
    delete_namespace kubecost
  else
    log "Retained namespace and Kubecost PersistentVolumeClaims: kubecost"
  fi
}

cleanup_otel_lightweight() {
  delete_namespace playground-otel
}

cleanup_otel_demo() {
  uninstall_release otel-demo otel-demo
  delete_namespace otel-demo
}

cleanup_cert_manager() {
  delete_namespace workshop-tls
  if [ "$DRY_RUN" = "true" ] || kubectl get crd clusterissuers.cert-manager.io >/dev/null 2>&1; then
    run_command kubectl delete clusterissuer \
      --selector app.kubernetes.io/part-of=azure-kubernetes-playground \
      --ignore-not-found
  fi
  uninstall_release cert-manager cert-manager
  delete_namespace cert-manager
  log "Retained cert-manager CRDs."
}

cleanup_tidb() {
  run_command kubectl delete tidbcluster basic \
    --namespace tidb-cluster \
    --ignore-not-found \
    --wait=true
  uninstall_release tidb-operator tidb-admin
  delete_namespace tidb-admin

  if [ "${CONFIRM_DELETE_DATA:-}" = "delete-persistent-workshop-data" ]; then
    run_command kubectl delete persistentvolumeclaim \
      --namespace tidb-cluster \
      --selector app.kubernetes.io/instance=basic,app.kubernetes.io/managed-by=tidb-operator

    if [ "$DRY_RUN" = "true" ]; then
      log "DRY RUN: patch retained TiDB PersistentVolumes to reclaimPolicy=Delete."
    else
      kubectl get persistentvolume \
        --selector app.kubernetes.io/namespace=tidb-cluster,app.kubernetes.io/managed-by=tidb-operator,app.kubernetes.io/instance=basic \
        --output name \
        | while IFS= read -r volume_name; do
            [ -n "$volume_name" ] || continue
            kubectl patch "$volume_name" \
              --patch '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
          done
    fi
    delete_namespace tidb-cluster
  else
    log "Retained namespace, TiDB PersistentVolumeClaims, and Retain-policy PersistentVolumes: tidb-cluster"
  fi
  log "Retained TiDB Operator CRDs."
}

cleanup_platform() {
  [ "${CONFIRM_PLATFORM_CLEANUP:-}" = "disable-aks-gateway-platform" ] \
    || die "Set CONFIRM_PLATFORM_CLEANUP=disable-aks-gateway-platform to disable the AKS Gateway platform."

  if [ "$DRY_RUN" != "true" ]; then
    GATEWAY_COUNT=$(kubectl get gateway --all-namespaces --output json | jq '.items | length')
    HTTP_ROUTE_COUNT=$(kubectl get httproute --all-namespaces --output json | jq '.items | length')
    [ "$GATEWAY_COUNT" -eq 0 ] && [ "$HTTP_ROUTE_COUNT" -eq 0 ] \
      || die "Delete all Gateway and HTTPRoute resources before disabling the platform."
  fi

  run_command az aks update \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --disable-app-routing-istio \
    --only-show-errors \
    --output none
  run_command az aks update \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$AKS_NAME" \
    --disable-gateway-api \
    --only-show-errors \
    --output none
}

case "$TARGET" in
  http) cleanup_http ;;
  monitoring) cleanup_monitoring ;;
  argocd) cleanup_argocd ;;
  workflows) cleanup_workflows ;;
  keycloak) cleanup_keycloak ;;
  open-webui) cleanup_open_webui ;;
  kubecost) cleanup_kubecost ;;
  otel-lightweight) cleanup_otel_lightweight ;;
  otel-demo) cleanup_otel_demo ;;
  cert-manager) cleanup_cert_manager ;;
  tidb) cleanup_tidb ;;
  all)
    cleanup_tidb
    cleanup_cert_manager
    cleanup_otel_demo
    cleanup_otel_lightweight
    cleanup_kubecost
    cleanup_open_webui
    cleanup_keycloak
    cleanup_workflows
    cleanup_argocd
    cleanup_monitoring
    cleanup_http
    delete_namespace workshop-gateway
    ;;
  platform) cleanup_platform ;;
  *) die "Unsupported cleanup target: ${TARGET}" ;;
esac

log "Cleanup completed for target: ${TARGET}"
log "Terraform-managed AKS, ACR, and resource group were not changed."
