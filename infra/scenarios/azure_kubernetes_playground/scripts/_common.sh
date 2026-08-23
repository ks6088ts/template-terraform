#!/bin/sh

set -eu

: "${SCRIPT_DIR:=$(CDPATH='' cd "$(dirname "$0")" && pwd)}"
SCENARIO_DIR=$(CDPATH='' cd "${SCRIPT_DIR}/.." && pwd)

: "${DRY_RUN:=false}"
: "${KUBECTL_WAIT_TIMEOUT:=5m}"
: "${HELM_WAIT_TIMEOUT:=15m}"
: "${AZURE_OPERATION_TIMEOUT_SECONDS:=1800}"
: "${POLL_INTERVAL_SECONDS:=10}"

: "${WORKSHOP_LABEL_KEY:=workshop.ks6088ts.com/gateway-access}"
: "${GATEWAY_NAMESPACE:=workshop-gateway}"
: "${GATEWAY_NAME:=workshop-gateway}"
: "${GATEWAY_CLASS_NAME:=approuting-istio}"

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

require_common_commands() {
  require_command az
  require_command date
  require_command jq
  require_command kubectl
  require_command terraform
}

require_value() {
  VALUE_NAME=$1
  VALUE=$2
  [ -n "$VALUE" ] || die "Required Terraform output is empty: ${VALUE_NAME}"
}

terraform_output_value() {
  terraform -chdir="${SCENARIO_DIR}" output -raw "$1"
}

load_terraform_outputs() {
  if [ -z "${RESOURCE_GROUP_NAME:-}" ]; then
    RESOURCE_GROUP_NAME=$(terraform_output_value resource_group_name) \
      || die "Unable to read resource_group_name. Apply the scenario first."
  fi
  if [ -z "${AKS_ID:-}" ]; then
    AKS_ID=$(terraform_output_value aks_id) \
      || die "Unable to read aks_id. Apply the scenario first."
  fi
  if [ -z "${AKS_NAME:-}" ]; then
    AKS_NAME=$(terraform_output_value aks_name) \
      || die "Unable to read aks_name. Apply the scenario first."
  fi
  if [ -z "${ACR_NAME:-}" ]; then
    ACR_NAME=$(terraform_output_value acr_name) \
      || die "Unable to read acr_name. Apply the scenario first."
  fi
  if [ -z "${ACR_LOGIN_SERVER:-}" ]; then
    ACR_LOGIN_SERVER=$(terraform_output_value acr_login_server) \
      || die "Unable to read acr_login_server. Apply the scenario first."
  fi
  if [ -z "${AZURE_SUBSCRIPTION_ID:-}" ]; then
    AZURE_SUBSCRIPTION_ID=$(printf '%s' "$AKS_ID" | awk -F/ '{print $3}')
  fi
}

require_scenario_outputs() {
  require_value resource_group_name "$RESOURCE_GROUP_NAME"
  require_value aks_id "$AKS_ID"
  require_value aks_name "$AKS_NAME"
  require_value acr_name "$ACR_NAME"
  require_value acr_login_server "$ACR_LOGIN_SERVER"
  require_value subscription_id "$AZURE_SUBSCRIPTION_ID"
}

validate_configuration() {
  case "$DRY_RUN" in
    true|false)
      ;;
    *)
      die "DRY_RUN must be true or false."
      ;;
  esac

  case "$KUBECTL_WAIT_TIMEOUT" in
    ''|*[!0-9smh]*)
      die "KUBECTL_WAIT_TIMEOUT must use kubectl duration syntax, for example 90s or 5m."
      ;;
  esac
  case "$HELM_WAIT_TIMEOUT" in
    ''|*[!0-9smh]*)
      die "HELM_WAIT_TIMEOUT must use Helm duration syntax, for example 10m or 1h."
      ;;
  esac

  validate_positive_integer AZURE_OPERATION_TIMEOUT_SECONDS "$AZURE_OPERATION_TIMEOUT_SECONDS"
  validate_positive_integer POLL_INTERVAL_SECONDS "$POLL_INTERVAL_SECONDS"
}

print_command() {
  printf 'DRY RUN:'
  printf ' %s' "$@"
  printf '\n'
}

run_command() {
  if [ "$DRY_RUN" = "true" ]; then
    print_command "$@"
    return 0
  fi

  "$@"
}

validate_positive_integer() {
  INTEGER_LABEL=$1
  INTEGER_VALUE=$2
  case "$INTEGER_VALUE" in
    ''|*[!0-9]*) die "${INTEGER_LABEL} must be a positive integer: ${INTEGER_VALUE}" ;;
  esac
  [ "$INTEGER_VALUE" -gt 0 ] || die "${INTEGER_LABEL} must be greater than zero."
}

require_target_subscription() {
  CURRENT_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
  [ "$CURRENT_SUBSCRIPTION_ID" = "$AZURE_SUBSCRIPTION_ID" ] \
    || die "Azure CLI subscription ${CURRENT_SUBSCRIPTION_ID} does not match Terraform subscription ${AZURE_SUBSCRIPTION_ID}."
}

require_cluster_context() {
  CURRENT_KUBECTL_CONTEXT=$(kubectl config current-context 2>/dev/null || true)
  [ "$CURRENT_KUBECTL_CONTEXT" = "$AKS_NAME" ] \
    || die "kubectl context ${CURRENT_KUBECTL_CONTEXT:-<none>} does not match AKS cluster ${AKS_NAME}. Run 01_connect_aks_cluster.sh first."
}

version_at_least() {
  CURRENT_VERSION=$1
  MINIMUM_VERSION=$2

  awk -v current="$CURRENT_VERSION" -v minimum="$MINIMUM_VERSION" 'BEGIN {
    current_count = split(current, current_parts, ".")
    minimum_count = split(minimum, minimum_parts, ".")
    part_count = current_count > minimum_count ? current_count : minimum_count
    for (part = 1; part <= part_count; part++) {
      current_value = current_parts[part] + 0
      minimum_value = minimum_parts[part] + 0
      if (current_value > minimum_value) exit 0
      if (current_value < minimum_value) exit 1
    }
    exit 0
  }'
}

wait_for_aks_power_state() {
  EXPECTED_POWER_STATE=$1
  START_EPOCH=$(date +%s)

  while :; do
    CURRENT_POWER_STATE=$(az aks show \
      --subscription "$AZURE_SUBSCRIPTION_ID" \
      --resource-group "$RESOURCE_GROUP_NAME" \
      --name "$AKS_NAME" \
      --query powerState.code \
      --output tsv)
    CURRENT_PROVISIONING_STATE=$(az aks show \
      --subscription "$AZURE_SUBSCRIPTION_ID" \
      --resource-group "$RESOURCE_GROUP_NAME" \
      --name "$AKS_NAME" \
      --query provisioningState \
      --output tsv)

    log "AKS powerState=${CURRENT_POWER_STATE} provisioningState=${CURRENT_PROVISIONING_STATE}"
    if [ "$CURRENT_POWER_STATE" = "$EXPECTED_POWER_STATE" ] && [ "$CURRENT_PROVISIONING_STATE" = "Succeeded" ]; then
      return 0
    fi

    NOW_EPOCH=$(date +%s)
    ELAPSED_SECONDS=$((NOW_EPOCH - START_EPOCH))
    [ "$ELAPSED_SECONDS" -lt "$AZURE_OPERATION_TIMEOUT_SECONDS" ] \
      || die "Timed out waiting for AKS power state ${EXPECTED_POWER_STATE}."
    sleep "$POLL_INTERVAL_SECONDS"
  done
}

wait_for_resource_jsonpath() {
  RESOURCE_REFERENCE=$1
  RESOURCE_NAMESPACE=$2
  JSONPATH_EXPRESSION=$3
  EXPECTED_VALUE=$4
  RESOURCE_LABEL=$5
  START_EPOCH=$(date +%s)

  while :; do
    CURRENT_VALUE=$(kubectl get "$RESOURCE_REFERENCE" \
      --namespace "$RESOURCE_NAMESPACE" \
      --output "jsonpath=${JSONPATH_EXPRESSION}" \
      2>/dev/null || true)
    log "${RESOURCE_LABEL}: ${CURRENT_VALUE:-pending}"
    if [ "$CURRENT_VALUE" = "$EXPECTED_VALUE" ]; then
      return 0
    fi

    NOW_EPOCH=$(date +%s)
    ELAPSED_SECONDS=$((NOW_EPOCH - START_EPOCH))
    [ "$ELAPSED_SECONDS" -lt "$AZURE_OPERATION_TIMEOUT_SECONDS" ] \
      || die "Timed out waiting for ${RESOURCE_LABEL} to become ${EXPECTED_VALUE}."
    sleep "$POLL_INTERVAL_SECONDS"
  done
}

ensure_workshop_namespace() {
  NAMESPACE_NAME=$1

  if kubectl get namespace "$NAMESPACE_NAME" >/dev/null 2>&1; then
    log "Namespace already exists: ${NAMESPACE_NAME}"
  else
    run_command kubectl create namespace "$NAMESPACE_NAME"
  fi

  run_command kubectl label namespace "$NAMESPACE_NAME" \
    "${WORKSHOP_LABEL_KEY}=true" \
    --overwrite
}

helm_upgrade_install() {
  RELEASE_NAME=$1
  CHART_NAME=$2
  RELEASE_NAMESPACE=$3
  CHART_VERSION=$4
  VALUES_FILE=$5

  ensure_workshop_namespace "$RELEASE_NAMESPACE"

  set -- upgrade --install "$RELEASE_NAME" "$CHART_NAME" \
    --namespace "$RELEASE_NAMESPACE" \
    --atomic \
    --wait \
    --timeout "$HELM_WAIT_TIMEOUT"
  if [ -n "$CHART_VERSION" ]; then
    set -- "$@" --version "$CHART_VERSION"
  fi
  if [ -n "$VALUES_FILE" ]; then
    [ -f "$VALUES_FILE" ] || die "Helm values file not found: ${VALUES_FILE}"
    set -- "$@" --values "$VALUES_FILE"
  fi

  run_command helm "$@"
}
