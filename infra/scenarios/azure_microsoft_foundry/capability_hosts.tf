resource "azapi_resource" "account_capability_host" {
  count = var.deploy_standard_agent ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-06-01"
  name                      = "${local.microsoft_foundry_name}-capHost"
  parent_id                 = module.microsoft_foundry.account_id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
    }
  }

  timeouts {
    create = "60m"
  }

  depends_on = [
    module.microsoft_foundry,
    azapi_resource.azure_ai_search_connection,
    azapi_resource.blob_storage_connection,
    azapi_resource.cosmosdb_connection,
    time_sleep.wait_for_rbac,
  ]
}

resource "azapi_resource" "project_capability_host" {
  count = var.deploy_standard_agent ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-06-01"
  name                      = "${module.microsoft_foundry.project_name}-capHost"
  parent_id                 = module.microsoft_foundry.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      storageConnections       = [module.blob_storage[0].account_name]
      vectorStoreConnections   = [module.azure_ai_search[0].name]
      threadStorageConnections = [module.cosmosdb[0].account_name]
    }
  }

  timeouts {
    create = "60m"
  }

  depends_on = [
    azapi_resource.account_capability_host,
  ]
}