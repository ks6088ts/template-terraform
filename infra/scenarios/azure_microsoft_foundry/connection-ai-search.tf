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
      authType = "ApiKey"
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.azure_ai_search[0].id
        location   = var.location
      }
    }
  }

  sensitive_body = {
    properties = {
      credentials = {
        key = module.azure_ai_search[0].primary_key
      }
    }
  }
}
