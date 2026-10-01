mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_monitor_activity_log_alert" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-observe/providers/Microsoft.Insights/activityLogAlerts/administrative-changes"
    }
  }
}

variables {
  name                  = "administrative-changes"
  resource_group_name   = "rg-observe"
  scopes                = ["/subscriptions/00000000-0000-0000-0000-000000000000"]
  resource_group_filter = "rg-workload"
  action_group_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-observe/providers/Microsoft.Insights/actionGroups/ops",
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-observe/providers/Microsoft.Insights/actionGroups/oncall",
  ]
}

run "administrative_resource_group_alert" {
  command = plan

  variables {
    tags = { environment = "test" }
  }

  assert {
    condition = alltrue([
      azurerm_monitor_activity_log_alert.this.location == "global",
      azurerm_monitor_activity_log_alert.this.resource_group_name == "rg-observe",
      toset(azurerm_monitor_activity_log_alert.this.scopes) == var.scopes,
      azurerm_monitor_activity_log_alert.this.criteria[0].category == "Administrative",
      azurerm_monitor_activity_log_alert.this.criteria[0].resource_group == "rg-workload",
      toset([for action in azurerm_monitor_activity_log_alert.this.action : action.action_group_id]) == var.action_group_ids,
      azurerm_monitor_activity_log_alert.this.tags.environment == "test",
      output.name == "administrative-changes",
      output.id == azurerm_monitor_activity_log_alert.this.id,
    ])
    error_message = "The global Administrative alert must filter by resource group name and notify every configured action group."
  }
}

run "no_actions_when_empty" {
  command = plan

  variables {
    action_group_ids = []
  }

  assert {
    condition     = length(azurerm_monitor_activity_log_alert.this.action) == 0
    error_message = "An empty action group set must not generate an action block."
  }
}

run "reject_empty_scopes" {
  command = plan

  variables {
    scopes = []
  }

  expect_failures = [var.scopes]
}

run "reject_resource_group_id_filter" {
  command = plan

  variables {
    resource_group_filter = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-workload"
  }

  expect_failures = [var.resource_group_filter]
}
