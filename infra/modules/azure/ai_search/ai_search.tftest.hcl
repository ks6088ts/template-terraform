mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_search_service" {
    defaults = {
      identity = {
        principal_id = "00000000-0000-0000-0000-000000000001"
        tenant_id    = "00000000-0000-0000-0000-000000000002"
      }
    }
  }
}

run "local_authentication_enabled_by_default" {
  command = plan

  variables {
    name                = "aisearchtest1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
    sku                 = "standard"
  }

  assert {
    condition     = azurerm_search_service.this.local_authentication_enabled
    error_message = "Azure AI Search local authentication must remain enabled by default."
  }

  assert {
    condition     = length(azurerm_search_service.this.identity) == 0
    error_message = "Azure AI Search managed identity must remain disabled by default."
  }

  assert {
    condition     = output.identity_principal_id == null
    error_message = "The identity principal ID must be null when managed identity is disabled."
  }
}

run "local_authentication_and_identity_can_be_configured" {
  command = plan

  variables {
    name                         = "aisearchtest1234"
    resource_group_name          = "rg-test"
    location                     = "japaneast"
    sku                          = "standard"
    local_authentication_enabled = false
    enable_identity              = true
  }

  assert {
    condition     = !azurerm_search_service.this.local_authentication_enabled
    error_message = "Azure AI Search local authentication must be disabled when requested."
  }


  assert {
    condition = alltrue([
      length(azurerm_search_service.this.identity) == 1,
      azurerm_search_service.this.identity[0].type == "SystemAssigned",
    ])
    error_message = "Azure AI Search must use a system-assigned managed identity when requested."
  }

  assert {
    condition     = output.identity_principal_id == azurerm_search_service.this.identity[0].principal_id
    error_message = "The identity principal output must match the Azure AI Search identity."
  }
}