mock_provider "azurerm" {
  override_during = plan
}

mock_provider "azapi" {
  override_during = plan
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

  assert {
    condition     = length(module.azure_ai_search) == 0
    error_message = "Azure AI Search must not be deployed by default."
  }

  assert {
    condition     = output.azure_ai_search_name == null
    error_message = "The Azure AI Search output must be null when deployment is disabled."
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