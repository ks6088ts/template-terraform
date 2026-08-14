resource "azapi_resource" "azure_ai_search_connection" {
  count = var.deploy_standard_agent ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = module.azure_ai_search[0].name
  parent_id                 = module.microsoft_foundry.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "CognitiveSearch"
      target   = module.azure_ai_search[0].endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.azure_ai_search[0].id
        location   = var.location
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.search_index_data_contributor,
    azurerm_role_assignment.search_service_contributor,
  ]
}

resource "azapi_resource" "blob_storage_connection" {
  count = var.deploy_standard_agent ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = module.blob_storage[0].account_name
  parent_id                 = module.microsoft_foundry.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = module.blob_storage[0].primary_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.blob_storage[0].account_id
        location   = var.location
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.storage_blob_data_contributor,
  ]
}

resource "azapi_resource" "cosmosdb_connection" {
  count = var.deploy_standard_agent ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = module.cosmosdb[0].account_name
  parent_id                 = module.microsoft_foundry.project_id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "CosmosDb"
      target   = module.cosmosdb[0].account_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.cosmosdb[0].account_id
        location   = var.location
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.cosmos_db_operator,
  ]
}