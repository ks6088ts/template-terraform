mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_servicebus_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ServiceBus/namespaces/servicebus-test"
    }
  }

  mock_resource "azurerm_servicebus_queue" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ServiceBus/namespaces/servicebus-test/queues/orders"
    }
  }

  mock_resource "azurerm_servicebus_topic" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ServiceBus/namespaces/servicebus-test/topics/events"
    }
  }

  mock_resource "azurerm_servicebus_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ServiceBus/namespaces/servicebus-test/topics/events/subscriptions/processor"
    }
  }

  mock_resource "azurerm_role_assignment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ServiceBus/namespaces/servicebus-test/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000002"
    }
  }
}

run "secure_standard_topology" {
  command = plan

  variables {
    name                = "servicebus-test"
    resource_group_name = "rg-test"
    location            = "japaneast"
    queue_name          = "orders"
    topic_name          = "events"
    subscription_name   = "processor"
  }

  assert {
    condition = alltrue([
      azurerm_servicebus_namespace.this.sku == "Standard",
      azurerm_servicebus_namespace.this.capacity == 0,
      azurerm_servicebus_namespace.this.public_network_access_enabled,
      !azurerm_servicebus_namespace.this.local_auth_enabled,
      azurerm_servicebus_namespace.this.minimum_tls_version == "1.2",
      length(azurerm_servicebus_namespace.this.tags) == 0,
    ])
    error_message = "The Service Bus namespace must use the economical secure Standard defaults."
  }

  assert {
    condition = alltrue([
      azurerm_servicebus_queue.this.name == "orders",
      azurerm_servicebus_queue.this.namespace_id == azurerm_servicebus_namespace.this.id,
      azurerm_servicebus_topic.this.name == "events",
      azurerm_servicebus_topic.this.namespace_id == azurerm_servicebus_namespace.this.id,
      azurerm_servicebus_subscription.this.name == "processor",
      azurerm_servicebus_subscription.this.topic_id == azurerm_servicebus_topic.this.id,
      azurerm_servicebus_subscription.this.max_delivery_count == 10,
      length(azurerm_role_assignment.data_sender) == 0,
      length(azurerm_role_assignment.data_receiver) == 0,
    ])
    error_message = "The module must create one queue, topic, and subscription without optional role assignments."
  }

  assert {
    condition = alltrue([
      output.namespace_id == azurerm_servicebus_namespace.this.id,
      output.namespace_name == "servicebus-test",
      output.namespace_fqdn == "servicebus-test.servicebus.windows.net",
      output.queue_id == azurerm_servicebus_queue.this.id,
      output.queue_name == "orders",
      output.topic_id == azurerm_servicebus_topic.this.id,
      output.topic_name == "events",
      output.subscription_id == azurerm_servicebus_subscription.this.id,
      output.subscription_name == "processor",
      output.sender_role_assignment_id == null,
      output.receiver_role_assignment_id == null,
    ])
    error_message = "The module outputs must expose resource metadata without secrets or connection strings."
  }
}

run "operator_roles" {
  command = plan

  variables {
    name                  = "servicebus-test"
    resource_group_name   = "rg-test"
    location              = "japaneast"
    queue_name            = "orders"
    topic_name            = "events"
    subscription_name     = "processor"
    operator_principal_id = "00000000-0000-0000-0000-000000000001"
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.data_sender) == 1,
      azurerm_role_assignment.data_sender[0].scope == azurerm_servicebus_namespace.this.id,
      azurerm_role_assignment.data_sender[0].role_definition_name == "Azure Service Bus Data Sender",
      azurerm_role_assignment.data_sender[0].principal_id == var.operator_principal_id,
      length(azurerm_role_assignment.data_receiver) == 1,
      azurerm_role_assignment.data_receiver[0].scope == azurerm_servicebus_namespace.this.id,
      azurerm_role_assignment.data_receiver[0].role_definition_name == "Azure Service Bus Data Receiver",
      azurerm_role_assignment.data_receiver[0].principal_id == var.operator_principal_id,
      output.sender_role_assignment_id == azurerm_role_assignment.data_sender[0].id,
      output.receiver_role_assignment_id == azurerm_role_assignment.data_receiver[0].id,
    ])
    error_message = "The operator principal must receive sender and receiver roles at namespace scope."
  }
}

run "premium_capacity" {
  command = plan

  variables {
    name                = "servicebus-premium"
    resource_group_name = "rg-test"
    location            = "japaneast"
    sku                 = "Premium"
    premium_capacity    = 4
    queue_name          = "orders"
    topic_name          = "events"
    subscription_name   = "processor"
  }

  assert {
    condition = alltrue([
      azurerm_servicebus_namespace.this.sku == "Premium",
      azurerm_servicebus_namespace.this.capacity == 4,
      azurerm_servicebus_namespace.this.public_network_access_enabled,
      !azurerm_servicebus_namespace.this.local_auth_enabled,
      azurerm_servicebus_namespace.this.minimum_tls_version == "1.2",
    ])
    error_message = "Premium SKU must use the configured valid messaging unit capacity and secure namespace settings."
  }
}
