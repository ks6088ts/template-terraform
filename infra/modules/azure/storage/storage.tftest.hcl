mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_storage_account" {
    defaults = {
      id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest1234"
      primary_access_key     = "mock-access-key"
      primary_queue_endpoint = "https://sttest1234.queue.core.windows.net/"
    }
  }

  mock_resource "azurerm_storage_queue" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest1234/queueServices/default/queues/sttest-queue"
    }
  }

  mock_resource "azurerm_role_assignment" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest1234/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000005"
    }
  }
}

run "default_storage" {
  command = plan

  variables {
    name                 = "test"
    storage_account_name = "sttest1234"
    resource_group_name  = "rg-test"
    location             = "japaneast"
  }

  assert {
    condition = alltrue([
      azurerm_storage_account.this.account_tier == "Standard",
      azurerm_storage_account.this.account_replication_type == "LRS",
      azurerm_storage_account.this.shared_access_key_enabled,
      length(azurerm_storage_queue.this) == 0,
      length(azurerm_role_assignment.queue_data_contributor) == 0,
      output.queue_id == null,
    ])
    error_message = "The Storage module defaults must remain backward compatible."
  }
}

run "entra_queue" {
  command = plan

  variables {
    name                                = "test"
    storage_account_name                = "sttest1234"
    resource_group_name                 = "rg-test"
    location                            = "japaneast"
    create_queue                        = true
    shared_access_key_enabled           = false
    queue_data_contributor_principal_id = "00000000-0000-0000-0000-000000000006"
  }

  assert {
    condition = alltrue([
      !azurerm_storage_account.this.shared_access_key_enabled,
      length(azurerm_storage_queue.this) == 1,
      azurerm_storage_queue.this[0].name == "sttest-queue",
      length(azurerm_role_assignment.queue_data_contributor) == 1,
      azurerm_role_assignment.queue_data_contributor[0].role_definition_name == "Storage Queue Data Contributor",
      azurerm_role_assignment.queue_data_contributor[0].principal_id == "00000000-0000-0000-0000-000000000006",
      output.primary_access_key == null,
      output.primary_queue_endpoint == "https://sttest1234.queue.core.windows.net/",
    ])
    error_message = "An Entra-only queue must create the Queue data-plane role and suppress the shared key output."
  }
}
