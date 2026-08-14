mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azuremicrosoftfoundry-test1234"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/stmsfoundrytest1234"
      primary_blob_endpoint = "https://stmsfoundrytest1234.blob.core.windows.net/"
    }
  }
}

mock_provider "azapi" {
  override_during = plan

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.CognitiveServices/accounts/test/projects/test"
      output = {
        identity = {
          principalId = "00000000-0000-0000-0000-000000000001"
        }
      }
    }
  }
}

mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "test1234"
    }
  }
}

run "blob_storage_disabled_by_default" {
  command = plan

  variables {
    deploy_azure_ai_search = false
    deploy_blob_storage    = false
    model_deployments      = []
  }

  assert {
    condition     = length(module.blob_storage) == 0
    error_message = "Azure Blob Storage must not be deployed by default."
  }

  assert {
    condition     = length(azurerm_role_assignment.blob_storage_data_contributor) == 0
    error_message = "The Blob Storage role assignment must not be created when deployment is disabled."
  }

  assert {
    condition     = length(azapi_resource.blob_storage_connection) == 0
    error_message = "The Blob Storage connection must not be created when deployment is disabled."
  }

  assert {
    condition = alltrue([
      output.blob_storage_account_id == null,
      output.blob_storage_account_name == null,
      output.blob_storage_endpoint == null,
      output.blob_storage_connection_id == null,
    ])
    error_message = "The Blob Storage outputs must be null when deployment is disabled."
  }
}

run "blob_storage_enabled" {
  command = plan

  variables {
    deploy_azure_ai_search = false
    deploy_blob_storage    = true
    model_deployments      = []
  }

  assert {
    condition     = length(module.blob_storage) == 1
    error_message = "Azure Blob Storage must be deployed when explicitly enabled."
  }

  assert {
    condition     = module.blob_storage[0].account_name == "stmsfoundrytest1234"
    error_message = "The Storage account name must use the scenario resource suffix."
  }

  assert {
    condition     = length(azurerm_role_assignment.blob_storage_data_contributor) == 1
    error_message = "One Blob Storage role assignment must be created when deployment is enabled."
  }

  assert {
    condition     = azurerm_role_assignment.blob_storage_data_contributor[0].scope == module.blob_storage[0].account_id
    error_message = "The Blob Storage role assignment scope must be the Storage account."
  }

  assert {
    condition     = azurerm_role_assignment.blob_storage_data_contributor[0].role_definition_name == "Storage Blob Data Contributor"
    error_message = "The Foundry project identity must receive the Storage Blob Data Contributor role."
  }

  assert {
    condition     = azurerm_role_assignment.blob_storage_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id
    error_message = "The Blob Storage role assignment principal must be the Microsoft Foundry project identity."
  }

  assert {
    condition     = azurerm_role_assignment.blob_storage_data_contributor[0].principal_type == "ServicePrincipal"
    error_message = "The Blob Storage role assignment principal type must be ServicePrincipal."
  }

  assert {
    condition     = length(azapi_resource.blob_storage_connection) == 1
    error_message = "One Blob Storage connection must be created when deployment is enabled."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].type == "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
    error_message = "The Blob Storage connection must be scoped to the Microsoft Foundry project."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].parent_id == module.microsoft_foundry.project_id
    error_message = "The Blob Storage connection parent must be the Microsoft Foundry project."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].name == module.blob_storage[0].account_name
    error_message = "The Blob Storage connection name must match the Storage account name."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].body.properties.category == "AzureStorageAccount"
    error_message = "The Blob Storage connection category must be AzureStorageAccount."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].body.properties.authType == "AAD"
    error_message = "The Blob Storage connection must use AAD authentication."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].body.properties.target == module.blob_storage[0].primary_blob_endpoint
    error_message = "The Blob Storage connection target must match the primary Blob endpoint."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].body.properties.metadata.ResourceId == module.blob_storage[0].account_id
    error_message = "The Blob Storage connection metadata must contain the Storage account resource ID."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].body.properties.metadata.ApiType == "Azure"
    error_message = "The Blob Storage connection metadata API type must be Azure."
  }

  assert {
    condition     = azapi_resource.blob_storage_connection[0].body.properties.metadata.location == var.location
    error_message = "The Blob Storage connection metadata location must match the scenario location."
  }

  assert {
    condition     = !contains(keys(azapi_resource.blob_storage_connection[0].body.properties), "credentials")
    error_message = "The AAD Blob Storage connection must not contain credentials."
  }

  assert {
    condition = alltrue([
      output.blob_storage_account_id == module.blob_storage[0].account_id,
      output.blob_storage_account_name == module.blob_storage[0].account_name,
      output.blob_storage_endpoint == module.blob_storage[0].primary_blob_endpoint,
      output.blob_storage_connection_id == azapi_resource.blob_storage_connection[0].id,
    ])
    error_message = "The Blob Storage outputs must match the created resources."
  }
}