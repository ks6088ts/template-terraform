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
  resource_name   = "${trim(substr(var.name, 0, 19), "-")}-${local.resource_suffix}"
}

# =============================================================================
# Microsoft Entra ID Authentication (opt-in)
# =============================================================================

data "azuread_client_config" "current" {
  count = var.enable_authentication ? 1 : 0
}

resource "random_uuid" "user_impersonation_scope" {
  count = var.enable_authentication ? 1 : 0
}

resource "azuread_application" "container_app" {
  count = var.enable_authentication ? 1 : 0

  display_name     = "app-${local.resource_name}"
  owners           = [data.azuread_client_config.current[0].object_id]
  sign_in_audience = "AzureADMyOrg"

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Access the MCP server on behalf of the signed-in user"
      admin_consent_display_name = "Access the MCP server"
      enabled                    = true
      id                         = random_uuid.user_impersonation_scope[0].result
      type                       = "User"
      user_consent_description   = "Access the MCP server on your behalf"
      user_consent_display_name  = "Access the MCP server"
      value                      = "user_impersonation"
    }
  }

  lifecycle {
    ignore_changes = [identifier_uris]
  }
}

resource "azuread_application_identifier_uri" "container_app" {
  count = var.enable_authentication ? 1 : 0

  application_id = azuread_application.container_app[0].id
  identifier_uri = "api://${azuread_application.container_app[0].client_id}"
}

resource "azuread_application_pre_authorized" "azure_cli" {
  count = var.enable_authentication ? 1 : 0

  application_id       = azuread_application.container_app[0].id
  authorized_client_id = var.azure_cli_client_id
  permission_ids       = [random_uuid.user_impersonation_scope[0].result]
}

resource "azuread_service_principal" "container_app" {
  count = var.enable_authentication ? 1 : 0

  client_id                    = azuread_application.container_app[0].client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current[0].object_id]
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
# Container Registry
# =============================================================================

module "container_registry" {
  count  = var.enable_public_acr ? 1 : 0
  source = "../../modules/azure/container_registry"

  name                          = local.resource_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  sku                           = var.acr_sku
  admin_enabled                 = false
  anonymous_pull_enabled        = true
  public_network_access_enabled = true
  tags                          = var.tags
}

# =============================================================================
# Log Analytics Workspace
# =============================================================================

module "log_analytics" {
  source = "../../modules/azure/log_analytics"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
}

# =============================================================================
# Application Insights
# =============================================================================

module "application_insights" {
  count  = var.enable_application_insights ? 1 : 0
  source = "../../modules/azure/application_insights"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  workspace_id        = module.log_analytics.id
  application_type    = var.application_insights_type
  sampling_percentage = var.application_insights_sampling_percentage
}

# =============================================================================
# Container Apps
# =============================================================================

locals {
  # Application Insights connection string is sensitive, so it is stored as a
  # Container App secret and referenced from an environment variable.
  application_insights_secret_name = "applicationinsights-connection-string"

  application_insights_secrets = var.enable_application_insights ? [{
    name  = local.application_insights_secret_name
    value = module.application_insights[0].connection_string
  }] : []

  application_insights_env_vars = var.enable_application_insights ? [{
    name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
    secret_name = local.application_insights_secret_name
  }] : []

  authentication = var.enable_authentication ? {
    client_id            = azuread_application.container_app[0].client_id
    tenant_auth_endpoint = "https://login.microsoftonline.com/${data.azuread_client_config.current[0].tenant_id}/v2.0"
    allowed_audiences    = [azuread_application_identifier_uri.container_app[0].identifier_uri]
    allowed_applications = [var.azure_cli_client_id]
  } : null
}

module "container_apps" {
  source = "../../modules/azure/container_apps"

  name                       = local.resource_name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  tags                       = var.tags
  log_analytics_workspace_id = module.log_analytics.id
  container_image            = var.container_image
  container_command          = var.container_command
  cpu                        = var.cpu
  memory                     = var.memory
  min_replicas               = var.min_replicas
  max_replicas               = var.max_replicas
  target_port                = var.container_port
  env_vars                   = concat(local.application_insights_env_vars, var.env_vars)
  secrets                    = concat(local.application_insights_secrets, var.secrets)
  authentication             = local.authentication

  depends_on = [
    azuread_application_pre_authorized.azure_cli,
    azuread_service_principal.container_app,
  ]
}
