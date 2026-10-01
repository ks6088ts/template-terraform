mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000001"
      object_id       = "00000000-0000-0000-0000-000000000002"
      subscription_id = "00000000-0000-0000-0000-000000000003"
      tenant_id       = "00000000-0000-0000-0000-000000000004"
    }
  }
}

run "current_client" {
  command = plan

  assert {
    condition = alltrue([
      output.client_id == "00000000-0000-0000-0000-000000000001",
      output.object_id == "00000000-0000-0000-0000-000000000002",
      output.subscription_id == "00000000-0000-0000-0000-000000000003",
      output.tenant_id == "00000000-0000-0000-0000-000000000004",
    ])
    error_message = "The module must expose the authenticated Azure client configuration."
  }
}
