mock_provider "azurerm" {
  override_during = plan
}

run "local_authentication_enabled_by_default" {
  command = plan

  variables {
    name                = "tracing-test1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
    workspace_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
  }

  assert {
    condition     = azurerm_application_insights.this.local_authentication_enabled
    error_message = "Application Insights local authentication must remain enabled by default."
  }
}

run "local_authentication_can_be_disabled" {
  command = plan

  variables {
    name                         = "tracing-test1234"
    resource_group_name          = "rg-test"
    location                     = "japaneast"
    workspace_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
    local_authentication_enabled = false
  }

  assert {
    condition     = !azurerm_application_insights.this.local_authentication_enabled
    error_message = "Application Insights local authentication must be disabled when requested."
  }
}
