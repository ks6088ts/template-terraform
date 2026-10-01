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

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id                     = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.Storage/storageAccounts/stazuremessagtest1234"
      primary_queue_endpoint = "https://stazuremessagtest1234.queue.core.windows.net/"
    }
  }

  mock_resource "azurerm_storage_queue" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.Storage/storageAccounts/stazuremessagtest1234/queueServices/default/queues/stazuremessag-test1234-queue"
    }
  }

  mock_resource "azurerm_servicebus_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.ServiceBus/namespaces/sb-azuremessag-test1234"
    }
  }

  mock_resource "azurerm_servicebus_queue" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.ServiceBus/namespaces/sb-azuremessag-test1234/queues/queue"
    }
  }

  mock_resource "azurerm_servicebus_topic" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.ServiceBus/namespaces/sb-azuremessag-test1234/topics/topic"
    }
  }

  mock_resource "azurerm_servicebus_subscription" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.ServiceBus/namespaces/sb-azuremessag-test1234/topics/topic/subscriptions/subscription"
    }
  }

  mock_resource "azurerm_eventgrid_topic" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.EventGrid/topics/egt-azuremessag-test1234"
      endpoint = "https://egt-azuremessag-test1234.japaneast-1.eventgrid.azure.net/api/events"
    }
  }

  mock_resource "azurerm_eventhub_namespace" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.EventHub/namespaces/evhns-azuremessag-test1234"
    }
  }

  mock_resource "azurerm_eventhub" {
    defaults = {
      id            = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/rg-azuremessag-test1234/providers/Microsoft.EventHub/namespaces/evhns-azuremessag-test1234/eventhubs/events"
      partition_ids = ["0", "1"]
    }
  }

  mock_resource "azurerm_role_assignment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000005"
    }
  }
}

mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "test1234"
    }
  }
}

run "all_services_disabled_by_default" {
  command = plan

  assert {
    condition = alltrue([
      module.resource_group.name == "rg-azuremessaging-test1234",
      length(module.queue_storage) == 0,
      length(module.service_bus) == 0,
      length(module.event_grid) == 0,
      length(module.event_hubs) == 0,
      output.queue_storage_account_id == null,
      output.service_bus_namespace_id == null,
      output.event_grid_topic_id == null,
      output.event_hubs_namespace_id == null,
    ])
    error_message = "Messaging services must remain opt-in and disabled by default."
  }
}

run "all_services_enabled" {
  command = plan

  variables {
    enable_queue_storage = true
    enable_service_bus   = true
    enable_event_grid    = true
    enable_event_hubs    = true
  }

  assert {
    condition = alltrue([
      length(module.queue_storage) == 1,
      module.queue_storage[0].account_name == "stazuremessagingtest1234",
      module.queue_storage[0].queue_name == "stazuremessaging-test1234-queue",
      length(module.service_bus) == 1,
      module.service_bus[0].namespace_name == "sb-azuremessaging-test1234",
      module.service_bus[0].queue_name == "queue",
      module.service_bus[0].topic_name == "topic",
      module.service_bus[0].subscription_name == "subscription",
      length(module.event_grid) == 1,
      module.event_grid[0].topic_name == "egt-azuremessaging-test1234",
      length(module.event_hubs) == 1,
      module.event_hubs[0].namespace_name == "evhns-azuremessaging-test1234",
      module.event_hubs[0].eventhub_name == "events",
      module.event_hubs[0].consumer_group_name == "$Default",
    ])
    error_message = "Enabling all flags must compose the expected economical messaging topology."
  }

  assert {
    condition = alltrue([
      output.operator_principal_id == "00000000-0000-0000-0000-000000000002",
      output.queue_storage_endpoint == "https://stazuremessagtest1234.queue.core.windows.net/",
      output.service_bus_namespace_fqdn == "sb-azuremessaging-test1234.servicebus.windows.net",
      output.event_grid_topic_endpoint == "https://egt-azuremessag-test1234.japaneast-1.eventgrid.azure.net/api/events",
      output.event_hubs_namespace_fqdn == "evhns-azuremessaging-test1234.servicebus.windows.net",
      output.event_hub_consumer_group_name == "$Default",
    ])
    error_message = "Scenario outputs must expose nonsecret endpoints and entity names for Entra-authenticated validation."
  }
}

run "operator_override" {
  command = plan

  variables {
    enable_event_grid     = true
    operator_principal_id = "00000000-0000-0000-0000-000000000006"
  }

  assert {
    condition     = output.operator_principal_id == "00000000-0000-0000-0000-000000000006"
    error_message = "An explicit operator principal ID must override the Terraform caller."
  }
}
