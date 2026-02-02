data "azurerm_subscription" "this" {
}

data "azuread_client_config" "this" {
}

data "azuread_application_published_app_ids" "this" {
}

data "azuread_service_principal" "this" {
  client_id = data.azuread_application_published_app_ids.this.result["MicrosoftGraph"]
}

resource "azuread_application" "this" {
  display_name = var.service_principal_name
  owners = [
    data.azuread_client_config.this.object_id,
  ]
  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.this.result["MicrosoftGraph"]
    dynamic "resource_access" {
      for_each = var.resource_access_permissions
      content {
        id   = data.azuread_service_principal.this.app_role_ids[resource_access.value.resource_access_permission_name]
        type = resource_access.value.type
      }
    }
  }
}

resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = false
  owners = [
    data.azuread_client_config.this.object_id,
  ]
}

resource "azurerm_role_assignment" "this" {
  scope                = data.azurerm_subscription.this.id
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}

resource "azuread_service_principal_password" "this" {
  service_principal_id = azuread_service_principal.this.id
  # Security: Set password expiration to enforce credential rotation (1 year from now)
  end_date = timeadd(timestamp(), "8760h")

  lifecycle {
    ignore_changes = [end_date]
  }
}

resource "azuread_application_federated_identity_credential" "this" {
  application_id = azuread_application.this.id
  display_name   = var.service_principal_name
  description    = "federated identity credential for ${var.service_principal_name}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_organization}/${var.github_repository}:environment:${var.github_environment}"
}
