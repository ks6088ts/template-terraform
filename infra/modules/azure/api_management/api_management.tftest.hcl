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
    condition     = output.identity_type == "SystemAssigned"
    error_message = "The identity type output must report the system-assigned identity."
  }
}

run "user_assigned_identity_and_network_enabled" {
  command = plan

  variables {
    name                            = "apim-test1234"
    resource_group_name             = "rg-test"
    location                        = "japaneast"
    publisher_name                  = "Example Organization"
    publisher_email                 = "admin@example.com"
    sku_name                        = "Developer_1"
    enable_system_assigned_identity = true
    user_assigned_identity_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-apim"
    ]
    public_network_access_enabled = false
    virtual_network_type          = "Internal"
    virtual_network_subnet_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-apim"
  }

  assert {
    condition = alltrue([
      azurerm_api_management.this.identity[0].type == "SystemAssigned, UserAssigned",
      length(azurerm_api_management.this.identity[0].identity_ids) == 1,
      !azurerm_api_management.this.public_network_access_enabled,
      azurerm_api_management.this.virtual_network_type == "Internal",
      azurerm_api_management.this.virtual_network_configuration[0].subnet_id == var.virtual_network_subnet_id,
    ])
    error_message = "The combined identity and private virtual network configuration must be preserved."
  }
}

run "network_mode_requires_subnet" {
  command = plan

  variables {
    name                          = "apim-test1234"
    resource_group_name           = "rg-test"
    location                      = "japaneast"
    publisher_name                = "Example Organization"
    publisher_email               = "admin@example.com"
    sku_name                      = "Developer_1"
    virtual_network_type          = "Internal"
    public_network_access_enabled = false
  }

  expect_failures = [azurerm_api_management.this]
}
