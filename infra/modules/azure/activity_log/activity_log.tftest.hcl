mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_monitor_diagnostic_setting" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000|subscription-activity"
    }
  }
}

variables {
  name                       = "subscription-activity"
  subscription_id            = "00000000-0000-0000-0000-000000000000"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
}

run "all_subscription_categories_by_default" {
  command = plan

  assert {
    condition = alltrue([
      azurerm_monitor_diagnostic_setting.this.target_resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000",
      azurerm_monitor_diagnostic_setting.this.log_analytics_workspace_id == var.log_analytics_workspace_id,
      toset([for log in azurerm_monitor_diagnostic_setting.this.enabled_log : log.category]) == toset([
        "Administrative", "Security", "ServiceHealth", "Alert", "Recommendation", "Policy", "Autoscale", "ResourceHealth",
      ]),
      output.name == "subscription-activity",
      output.id == azurerm_monitor_diagnostic_setting.this.id,
    ])
    error_message = "All eight subscription Activity Log categories must be exported to the selected workspace."
  }
}

run "selected_categories" {
  command = plan

  variables {
    categories = ["Administrative", "Security"]
  }

  assert {
    condition     = toset([for log in azurerm_monitor_diagnostic_setting.this.enabled_log : log.category]) == toset(["Administrative", "Security"])
    error_message = "Only the requested Activity Log categories must be enabled."
  }
}

run "reject_unsupported_category" {
  command = plan

  variables {
    categories = ["NotSupported"]
  }

  expect_failures = [var.categories]
}

run "reject_subscription_resource_id" {
  command = plan

  variables {
    subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.subscription_id]
}
