resource "random_string" "unique" {
  length      = 5
  min_numeric = 5
  numeric     = true
  special     = false
  lower       = true
  upper       = false
}

# Resource Group
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name}-${random_string.unique.result}"
  location = var.location
  tags     = var.tags
}

# Microsoft Foundry Account
resource "azapi_resource" "account" {
  name     = local.account_name
  location = var.location
  tags     = var.tags

  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  parent_id                 = azurerm_resource_group.this.id
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
      disableLocalAuth = false

      # Specifies that this is an AI Foundry resource
      allowProjectManagement = true

      # Set custom subdomain name for DNS names created for this Foundry resource
      customSubDomainName = local.account_name
    }
  }
}

# Microsoft Foundry Project
resource "azapi_resource" "project" {
  name     = local.project_name
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
      displayName = "project"
      description = "My first project"
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
