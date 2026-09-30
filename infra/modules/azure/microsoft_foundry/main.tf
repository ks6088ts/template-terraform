# Microsoft Foundry Account
resource "azapi_resource" "account" {
  name     = var.name
  location = var.location
  tags     = var.tags

  type      = "Microsoft.CognitiveServices/accounts@2026-07-01"
  parent_id = var.resource_group_id
  # AzAPI 2.13 doesn't yet embed the documented 2026-07-01 Foundry ARM schemas.
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
      allowProjectManagement        = true
      customSubDomainName           = var.name
      disableLocalAuth              = var.disable_local_auth
      publicNetworkAccess           = "Enabled"
      restrictOutboundNetworkAccess = false
    }
  }
}

# Microsoft Foundry Project
resource "azapi_resource" "project" {
  name     = "${var.name}project"
  location = var.location
  tags     = var.tags

  type                      = "Microsoft.CognitiveServices/accounts/projects@2026-07-01"
  parent_id                 = azapi_resource.account.id
  schema_validation_enabled = false
  response_export_values = [
    "identity.principalId",
    "properties.internalId",
  ]
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

  name                      = each.value.name
  type                      = "Microsoft.CognitiveServices/accounts/deployments@2026-07-01"
  parent_id                 = azapi_resource.account.id
  schema_validation_enabled = false

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
      versionUpgradeOption = each.value.version_upgrade_option
    }
  }

  replace_triggers_refs = [
    "body.properties.model",
  ]
}
