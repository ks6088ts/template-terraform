mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_monitor_action_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/actionGroups/ag-observe"
    }
  }
}

variables {
  name                = "ag-observe"
  resource_group_name = "rg-test"
}

run "no_email_receivers_by_default" {
  command = plan

  assert {
    condition = alltrue([
      azurerm_monitor_action_group.this.short_name == "observe",
      azurerm_monitor_action_group.this.resource_group_name == "rg-test",
      length(azurerm_monitor_action_group.this.email_receiver) == 0,
      output.name == "ag-observe",
      output.id == azurerm_monitor_action_group.this.id,
    ])
    error_message = "The action group must use the default short name and omit email receivers unless configured."
  }
}

run "multiple_deterministic_email_receivers" {
  command = plan

  variables {
    short_name      = "ops"
    email_addresses = ["ops@example.com", "oncall@example.com", "ops@example.com"]
    tags            = { environment = "test" }
  }

  assert {
    condition = alltrue([
      azurerm_monitor_action_group.this.short_name == "ops",
      azurerm_monitor_action_group.this.tags.environment == "test",
      length(azurerm_monitor_action_group.this.email_receiver) == 2,
      toset([for receiver in azurerm_monitor_action_group.this.email_receiver : receiver.email_address]) == toset(["ops@example.com", "oncall@example.com"]),
      alltrue([
        for receiver in azurerm_monitor_action_group.this.email_receiver :
        receiver.use_common_alert_schema && receiver.name == "email-${substr(sha256(receiver.email_address), 0, 24)}"
      ]),
    ])
    error_message = "Each distinct email must receive a stable receiver name and use the common alert schema."
  }
}

run "reject_long_short_name" {
  command = plan

  variables {
    short_name = "more-than-twelve"
  }

  expect_failures = [var.short_name]
}

run "reject_invalid_email_address" {
  command = plan

  variables {
    email_addresses = ["not-an-email"]
  }

  expect_failures = [var.email_addresses]
}
