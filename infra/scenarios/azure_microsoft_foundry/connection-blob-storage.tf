resource "azurerm_role_assignment" "blob_storage_data_contributor" {
  count = var.deploy_blob_storage ? 1 : 0

  scope                = module.blob_storage[0].account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.microsoft_foundry.project_principal_id
  principal_type       = "ServicePrincipal"
}

resource "azapi_resource" "blob_storage_connection" {
  count = var.deploy_blob_storage ? 1 : 0

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
    azurerm_role_assignment.blob_storage_data_contributor,
  ]
}