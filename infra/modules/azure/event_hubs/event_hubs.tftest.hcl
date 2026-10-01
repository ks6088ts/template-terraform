mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_eventhub_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventHub/namespaces/eventhubs-test"
    }
  }

  mock_resource "azurerm_eventhub" {
    defaults = {
      id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventHub/namespaces/eventhubs-test/eventhubs/events"
      partition_ids = ["0", "1"]
    }
  }

  mock_resource "azurerm_role_assignment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.EventHub/namespaces/eventhubs-test/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000002"
    }
  }
}

run "basic_defaults_with_rbac" {
  command = plan

  variables {
    name                  = "eventhubs-test"
    resource_group_name   = "rg-test"
    location              = "japaneast"
    eventhub_name         = "events"
    operator_principal_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition = alltrue([
      azurerm_eventhub_namespace.this.sku == "Basic",
      azurerm_eventhub_namespace.this.capacity == 1,
      azurerm_eventhub_namespace.this.public_network_access_enabled,
      !azurerm_eventhub_namespace.this.local_authentication_enabled,
      azurerm_eventhub_namespace.this.minimum_tls_version == "1.2",
      azurerm_eventhub.this.partition_count == 2,
      azurerm_eventhub.this.message_retention == 1,
    ])
    error_message = "The Event Hubs namespace and event hub must use the economical secure defaults."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.data_sender) == 1,
      azurerm_role_assignment.data_sender[0].scope == azurerm_eventhub_namespace.this.id,
      azurerm_role_assignment.data_sender[0].role_definition_name == "Azure Event Hubs Data Sender",
      azurerm_role_assignment.data_sender[0].principal_id == var.operator_principal_id,
      length(azurerm_role_assignment.data_receiver) == 1,
      azurerm_role_assignment.data_receiver[0].scope == azurerm_eventhub_namespace.this.id,
      azurerm_role_assignment.data_receiver[0].role_definition_name == "Azure Event Hubs Data Receiver",
      azurerm_role_assignment.data_receiver[0].principal_id == var.operator_principal_id,
    ])
    error_message = "The operator principal must receive sender and receiver roles at namespace scope."
  }

  assert {
    condition = alltrue([
      output.namespace_name == "eventhubs-test",
      output.namespace_fqdn == "eventhubs-test.servicebus.windows.net",
      output.eventhub_name == "events",
      toset(output.partition_ids) == toset(["0", "1"]),
      output.consumer_group_name == "$Default",
      output.sender_role_assignment_id == azurerm_role_assignment.data_sender[0].id,
      output.receiver_role_assignment_id == azurerm_role_assignment.data_receiver[0].id,
    ])
    error_message = "The module outputs must expose resource metadata without shared keys or connection strings."
  }
}

run "standard_customization" {
  command = plan

  variables {
    name                = "eventhubs-standard"
    resource_group_name = "rg-test"
    location            = "japaneast"
    tags = {
      environment = "test"
    }
    sku               = "Standard"
    capacity          = 4
    eventhub_name     = "telemetry"
    partition_count   = 8
    message_retention = 7
  }

  assert {
    condition = alltrue([
      azurerm_eventhub_namespace.this.sku == "Standard",
      azurerm_eventhub_namespace.this.capacity == 4,
      azurerm_eventhub_namespace.this.tags.environment == "test",
      azurerm_eventhub.this.name == "telemetry",
      azurerm_eventhub.this.partition_count == 8,
      azurerm_eventhub.this.message_retention == 7,
      length(azurerm_role_assignment.data_sender) == 0,
      length(azurerm_role_assignment.data_receiver) == 0,
      output.sender_role_assignment_id == null,
      output.receiver_role_assignment_id == null,
    ])
    error_message = "Standard SKU customization must be applied without creating optional RBAC assignments."
  }
}

run "basic_retention_is_rejected" {
  command = plan

  variables {
    name                = "eventhubs-test"
    resource_group_name = "rg-test"
    location            = "japaneast"
    eventhub_name       = "events"
    message_retention   = 2
  }

  expect_failures = [azurerm_eventhub.this]
}
