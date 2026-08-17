# =============================================================================
# Random String
# =============================================================================

module "random_string" {
  source = "../../modules/common/random_string"

  length      = 8
  min_numeric = 0
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

locals {
  resource_suffix = module.random_string.result
  resource_name   = "${trim(substr(var.name, 0, 46), "-")}-${local.resource_suffix}"
}

# =============================================================================
# Microsoft Entra ID Authentication
# =============================================================================

data "azuread_client_config" "current" {}

resource "random_uuid" "user_impersonation_scope" {}

resource "azuread_application" "function_app" {
  display_name     = "func-${local.resource_name}"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Access the Function App on behalf of the signed-in user"
      admin_consent_display_name = "Access the Function App"
      enabled                    = true
      id                         = random_uuid.user_impersonation_scope.result
      type                       = "User"
      user_consent_description   = "Access the Function App on your behalf"
      user_consent_display_name  = "Access the Function App"
      value                      = "user_impersonation"
    }
  }

  lifecycle {
    ignore_changes = [identifier_uris]
  }
}

resource "azuread_application_identifier_uri" "function_app" {
  application_id = azuread_application.function_app.id
  identifier_uri = "api://${azuread_application.function_app.client_id}"
}

resource "azuread_application_pre_authorized" "azure_cli" {
  application_id       = azuread_application.function_app.id
  authorized_client_id = var.azure_cli_client_id
  permission_ids       = [random_uuid.user_impersonation_scope.result]
}

resource "azuread_service_principal" "function_app" {
  client_id                    = azuread_application.function_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = local.resource_name
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Azure Functions Flex Consumption
# =============================================================================

module "functions_flex_consumption" {
  source = "../../modules/azure/functions_flex_consumption"

  name                 = local.resource_name
  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  tags                 = var.tags
  storage_account_name = "st${local.resource_suffix}"

  # Runtime configuration
  runtime_name    = var.runtime_name
  runtime_version = var.runtime_version

  # Scaling configuration
  maximum_instance_count = var.maximum_instance_count
  instance_memory_in_mb  = var.instance_memory_in_mb
  zone_redundant         = var.zone_redundant

  # Additional app settings
  app_settings = var.app_settings

  authentication = {
    client_id            = azuread_application.function_app.client_id
    tenant_auth_endpoint = "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/v2.0/"
    allowed_audiences    = [azuread_application_identifier_uri.function_app.identifier_uri]
    allowed_applications = [var.azure_cli_client_id]
    excluded_paths       = ["/api/hello-key"]
  }

  depends_on = [
    azuread_application_pre_authorized.azure_cli,
    azuread_service_principal.function_app,
  ]
}
