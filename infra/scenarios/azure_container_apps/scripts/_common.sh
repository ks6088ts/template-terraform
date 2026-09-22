#!/bin/sh

# shellcheck disable=SC2034

set -eu

: "${SCRIPT_DIR:=$(CDPATH='' cd "$(dirname "$0")" && pwd)}"
SCENARIO_DIR=$(CDPATH='' cd "${SCRIPT_DIR}/.." && pwd)
SOURCE_DIR="${SCENARIO_DIR}/src"
DEPLOYMENT_VARS_FILE="${SCENARIO_DIR}/deployment.auto.tfvars.json"

: "${IMAGE_REPOSITORY:=tasks-mcp-server}"
: "${IMAGE_TAG:=latest}"
: "${IMAGE_PLATFORM:=linux/amd64}"

TERRAFORM_OUTPUTS=""
RESOURCE_GROUP_NAME=""
ACR_ID=""
ACR_NAME=""
ACR_LOGIN_SERVER=""
AZURE_SUBSCRIPTION_ID=""
CONTAINER_APP_URL=""
AUTHENTICATION_IDENTIFIER_URI=""
IMAGE_TAG_REFERENCE=""

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

require_value() {
  VALUE_LABEL=$1
  VALUE_CONTENT=$2
  [ -n "$VALUE_CONTENT" ] || die "Terraform output is empty: ${VALUE_LABEL}. Run terraform apply first."
}

terraform_output_value() {
  printf '%s' "$TERRAFORM_OUTPUTS" | jq -r --arg output_name "$1" '
    .[$output_name].value as $value
    | if $value == null then empty
      elif ($value | type) == "string" then $value
      else ($value | tostring)
      end
  '
}

load_terraform_outputs() {
  if ! TERRAFORM_OUTPUTS=$(terraform -chdir="${SCENARIO_DIR}" output -json); then
    die "Unable to read Terraform outputs. Run terraform apply first."
  fi

  RESOURCE_GROUP_NAME=$(terraform_output_value resource_group_name)
  ACR_ID=$(terraform_output_value acr_id)
  ACR_NAME=$(terraform_output_value acr_name)
  ACR_LOGIN_SERVER=$(terraform_output_value acr_login_server)
  CONTAINER_APP_URL=$(terraform_output_value container_app_url)
  AUTHENTICATION_IDENTIFIER_URI=$(terraform_output_value container_app_authentication_identifier_uri)

  AZURE_SUBSCRIPTION_ID=""
  if [ -n "$ACR_ID" ]; then
    AZURE_SUBSCRIPTION_ID=$(printf '%s' "$ACR_ID" | cut -d/ -f3)
  fi
}

require_acr_outputs() {
  require_value acr_id "$ACR_ID"
  require_value acr_name "$ACR_NAME"
  require_value acr_login_server "$ACR_LOGIN_SERVER"
  require_value subscription_id "$AZURE_SUBSCRIPTION_ID"
}

set_image_tag_reference() {
  require_acr_outputs
  [ -n "$IMAGE_REPOSITORY" ] || die "IMAGE_REPOSITORY must not be empty."
  [ -n "$IMAGE_TAG" ] || die "IMAGE_TAG must not be empty."

  case "${IMAGE_REPOSITORY}:${IMAGE_TAG}" in
    *[!a-zA-Z0-9._/:@-]*) die "IMAGE_REPOSITORY and IMAGE_TAG contain unsupported characters." ;;
  esac

  IMAGE_TAG_REFERENCE="${ACR_LOGIN_SERVER}/${IMAGE_REPOSITORY}:${IMAGE_TAG}"
}
