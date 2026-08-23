mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_api_management" {
    defaults = {
      identity = {
        principal_id = "00000000-0000-0000-0000-000000000001"
        tenant_id    = "00000000-0000-0000-0000-000000000002"
      }
    }
  }

  mock_data "azurerm_api_management" {
    defaults = {
      identity = {
        principal_id = "00000000-0000-0000-0000-000000000001"
        tenant_id    = "00000000-0000-0000-0000-000000000002"
        type         = "SystemAssigned"
      }
    }
  }
}

run "system_assigned_identity_disabled_by_default" {
  command = plan

  variables {
    name                = "apim-test1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
    publisher_name      = "Example Organization"
    publisher_email     = "admin@example.com"
    sku_name            = "Consumption_0"
  }

  assert {
    condition     = length(azurerm_api_management.this.identity) == 0
    error_message = "The API Management identity must remain disabled by default."
  }

  assert {
    condition     = output.identity_principal_id == null
    error_message = "The identity principal ID must be null when the identity is disabled."
  }
}

run "system_assigned_identity_enabled" {
  command = plan

  variables {
    name                            = "apim-test1234"
    resource_group_name             = "rg-test"
    location                        = "japaneast"
    publisher_name                  = "Example Organization"
    publisher_email                 = "admin@example.com"
    sku_name                        = "Developer_1"
    enable_system_assigned_identity = true
  }

  assert {
    condition     = azurerm_api_management.this.identity[0].type == "SystemAssigned"
    error_message = "The API Management identity must be system-assigned when enabled."
  }

  assert {
    condition     = length(data.azurerm_api_management.this) == 1
    error_message = "The enabled identity must be resolved after the API Management resource update."
  }
}
