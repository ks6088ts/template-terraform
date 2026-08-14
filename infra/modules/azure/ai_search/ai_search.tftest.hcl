mock_provider "azurerm" {
  override_during = plan
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
}

run "local_authentication_can_be_disabled" {
  command = plan

  variables {
    name                         = "aisearchtest1234"
    resource_group_name          = "rg-test"
    location                     = "japaneast"
    sku                          = "standard"
    local_authentication_enabled = false
  }

  assert {
    condition     = !azurerm_search_service.this.local_authentication_enabled
    error_message = "Azure AI Search local authentication must be disabled when requested."
  }
}