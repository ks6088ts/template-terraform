mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_eventgrid_topic" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventGrid/topics/eg-test"
      endpoint = "https://eg-test.japaneast-1.eventgrid.azure.net/api/events"
    }
  }

  mock_resource "azurerm_role_assignment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventGrid/topics/eg-test/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000002"
    }
  }
}

run "secure_defaults" {
  command = plan

  variables {
    name                = "eg-test"
    resource_group_name = "rg-test"
    location            = "japaneast"
  }

  assert {
    condition = alltrue([
      azurerm_eventgrid_topic.this.input_schema == "EventGridSchema",
      azurerm_eventgrid_topic.this.public_network_access_enabled,
      !azurerm_eventgrid_topic.this.local_auth_enabled,
      length(azurerm_role_assignment.event_grid_data_sender) == 0,
      output.topic_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventGrid/topics/eg-test",
      output.topic_name == "eg-test",
      output.topic_endpoint == "https://eg-test.japaneast-1.eventgrid.azure.net/api/events",
      length(output.role_assignment_ids) == 0,
    ])
    error_message = "The Event Grid topic must use secure defaults and omit RBAC when no principal is supplied."
  }
}

run "operator_rbac" {
  command = plan

  variables {
    name                  = "eg-test"
    resource_group_name   = "rg-test"
    location              = "japaneast"
    operator_principal_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.event_grid_data_sender) == 1,
      azurerm_role_assignment.event_grid_data_sender[0].scope == azurerm_eventgrid_topic.this.id,
      azurerm_role_assignment.event_grid_data_sender[0].role_definition_name == "EventGrid Data Sender",
      azurerm_role_assignment.event_grid_data_sender[0].principal_id == "00000000-0000-0000-0000-000000000001",
      output.role_assignment_ids == ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventGrid/topics/eg-test/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000002"],
    ])
    error_message = "Supplying an operator principal must create the EventGrid Data Sender role assignment at topic scope."
  }
}

run "custom_input_schema" {
  command = plan

  variables {
    name                = "eg-test"
    resource_group_name = "rg-test"
    location            = "japaneast"
    input_schema        = "CustomEventSchema"
  }

  assert {
    condition     = azurerm_eventgrid_topic.this.input_schema == "CustomEventSchema"
    error_message = "The configured custom input schema must be forwarded to the Event Grid topic."
  }
}
