mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_search_service" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Search/searchServices/aisearchtest1234"
      endpoint = "https://aisearchtest1234.search.windows.net"
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

run "azure_ai_search_disabled_by_default" {
  command = plan

  variables {
    deploy_azure_ai_search = false
  }

  assert {
    condition     = length(module.azure_ai_search) == 0
    error_message = "Azure AI Search must not be deployed by default."
  }

  assert {
    condition     = output.azure_ai_search_name == null
    error_message = "The Azure AI Search output must be null when deployment is disabled."
  }

  assert {
    condition     = length(azapi_resource.azure_ai_search_connection) == 0
    error_message = "The Azure AI Search connection must not be created when deployment is disabled."
  }

  assert {
    condition     = length(azurerm_role_assignment.azure_ai_search_index_data_contributor) == 0
    error_message = "The Search Index Data Contributor assignment must not be created when deployment is disabled."
  }

  assert {
    condition     = length(azurerm_role_assignment.azure_ai_search_service_contributor) == 0
    error_message = "The Search Service Contributor assignment must not be created when deployment is disabled."
  }

  assert {
    condition     = output.azure_ai_search_connection_id == null
    error_message = "The Azure AI Search connection output must be null when deployment is disabled."
  }
}

run "azure_ai_search_enabled" {
  command = plan

  variables {
    deploy_azure_ai_search = true
    azure_ai_search_sku    = "free"
  }

  assert {
    condition     = length(module.azure_ai_search) == 1
    error_message = "Azure AI Search must be deployed when explicitly enabled."
  }

  assert {
    condition     = module.azure_ai_search[0].name == "aisearchtest1234"
    error_message = "The Azure AI Search service name must use the scenario resource suffix."
  }

  assert {
    condition     = length(azapi_resource.azure_ai_search_connection) == 1
    error_message = "One Azure AI Search connection must be created when deployment is enabled."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].type == "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
    error_message = "The Azure AI Search connection must be scoped to the Microsoft Foundry project."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].parent_id == module.microsoft_foundry.project_id
    error_message = "The Azure AI Search connection parent must be the Microsoft Foundry project."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].name == module.azure_ai_search[0].name
    error_message = "The Azure AI Search connection name must match the Azure AI Search service name."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].body.properties.category == "CognitiveSearch"
    error_message = "The Azure AI Search connection category must be CognitiveSearch."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].body.properties.authType == "AAD"
    error_message = "The Azure AI Search connection must use Microsoft Entra ID authentication."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].body.properties.target == module.azure_ai_search[0].endpoint
    error_message = "The Azure AI Search connection target must match the Azure AI Search endpoint."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].body.properties.metadata.ResourceId == module.azure_ai_search[0].id
    error_message = "The Azure AI Search connection metadata must contain the Azure AI Search resource ID."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].body.properties.metadata.ApiType == "Azure"
    error_message = "The Azure AI Search connection metadata API type must be Azure."
  }

  assert {
    condition     = azapi_resource.azure_ai_search_connection[0].body.properties.metadata.location == var.location
    error_message = "The Azure AI Search connection metadata location must match the scenario location."
  }

  assert {
    condition     = !contains(keys(azapi_resource.azure_ai_search_connection[0].body.properties), "credentials")
    error_message = "The Microsoft Entra ID connection must not contain credentials."
  }

  assert {
    condition     = length(azurerm_role_assignment.azure_ai_search_index_data_contributor) == 1
    error_message = "One Search Index Data Contributor assignment must be created when deployment is enabled."
  }

  assert {
    condition     = azurerm_role_assignment.azure_ai_search_index_data_contributor[0].role_definition_name == "Search Index Data Contributor"
    error_message = "The project identity must receive the Search Index Data Contributor role."
  }

  assert {
    condition = (
      azurerm_role_assignment.azure_ai_search_index_data_contributor[0].scope == module.azure_ai_search[0].id &&
      azurerm_role_assignment.azure_ai_search_index_data_contributor[0].principal_id == module.microsoft_foundry.project_principal_id
    )
    error_message = "The Search Index Data Contributor assignment must target the search service and project identity."
  }

  assert {
    condition     = length(azurerm_role_assignment.azure_ai_search_service_contributor) == 1
    error_message = "One Search Service Contributor assignment must be created when deployment is enabled."
  }

  assert {
    condition     = azurerm_role_assignment.azure_ai_search_service_contributor[0].role_definition_name == "Search Service Contributor"
    error_message = "The project identity must receive the Search Service Contributor role."
  }

  assert {
    condition = (
      azurerm_role_assignment.azure_ai_search_service_contributor[0].scope == module.azure_ai_search[0].id &&
      azurerm_role_assignment.azure_ai_search_service_contributor[0].principal_id == module.microsoft_foundry.project_principal_id
    )
    error_message = "The Search Service Contributor assignment must target the search service and project identity."
  }

  assert {
    condition     = output.azure_ai_search_connection_id == azapi_resource.azure_ai_search_connection[0].id
    error_message = "The Azure AI Search connection output must match the created connection ID."
  }
}

run "azure_ai_search_rejects_serverless_sku" {
  command = plan

  variables {
    azure_ai_search_sku = "serverless"
  }

  expect_failures = [
    var.azure_ai_search_sku,
  ]
}