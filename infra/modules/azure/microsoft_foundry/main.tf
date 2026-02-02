# Microsoft Foundry Account
resource "azapi_resource" "account" {
  name     = var.name
  location = var.location
  tags     = var.tags

  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  parent_id                 = var.resource_group_id
  schema_validation_enabled = false

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      # Support both Entra ID and API Key authentication for Cognitive Services account
      disableLocalAuth = var.disable_local_auth

      # Specifies that this is an AI Foundry resource
      allowProjectManagement = true

      # Set custom subdomain name for DNS names created for this Foundry resource
      customSubDomainName = var.name
    }
  }
}

# Microsoft Foundry Project
resource "azapi_resource" "project" {
  name     = "${var.name}project"
  location = var.location
  tags     = var.tags

  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  parent_id                 = azapi_resource.account.id
  schema_validation_enabled = false
  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      displayName = var.project_display_name
      description = var.project_description
    }
  }
}

# Microsoft Foundry Deployments
# NOTE: This requires parallelism=1 to avoid deployment conflicts
resource "azapi_resource" "deployment" {
  for_each = { for d in var.model_deployments : d.name => d }

  name      = each.value.name
  type      = "Microsoft.CognitiveServices/accounts/deployments@2023-05-01"
  parent_id = azapi_resource.account.id

  depends_on = [
    azapi_resource.account
  ]

  body = {
    sku = {
      name     = each.value.sku_name
      capacity = each.value.capacity
    }
    properties = {
      model = {
        format  = each.value.format
        name    = each.value.model
        version = each.value.version
      }
    }
  }
}
