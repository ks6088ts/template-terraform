resource "azurerm_role_assignment" "azure_ai_search_index_data_contributor" {
  count = var.deploy_azure_ai_search ? 1 : 0

  scope                            = module.azure_ai_search[0].id
  role_definition_name             = "Search Index Data Contributor"
  principal_id                     = module.microsoft_foundry.project_principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "azure_ai_search_service_contributor" {
  count = var.deploy_azure_ai_search ? 1 : 0

  scope                            = module.azure_ai_search[0].id
  role_definition_name             = "Search Service Contributor"
  principal_id                     = module.microsoft_foundry.project_principal_id
  skip_service_principal_aad_check = true
}

resource "azapi_resource" "azure_ai_search_connection" {
  count = var.deploy_azure_ai_search ? 1 : 0

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
    azurerm_role_assignment.azure_ai_search_index_data_contributor,
    azurerm_role_assignment.azure_ai_search_service_contributor,
  ]
}