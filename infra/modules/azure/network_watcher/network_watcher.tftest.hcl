mock_provider "azurerm" {
  override_during = plan

  mock_data "azurerm_network_watcher" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_japaneast"
    }
  }

  mock_resource "azurerm_network_watcher" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/NetworkWatcherRG/providers/Microsoft.Network/networkWatchers/NetworkWatcher_japaneast"
    }
  }
}

variables {
  name                = "NetworkWatcher_japaneast"
  resource_group_name = "NetworkWatcherRG"
  location            = "japaneast"
}

run "reuse_existing_by_default" {
  command = plan

  assert {
    condition = alltrue([
      length(azurerm_network_watcher.this) == 0,
      length(data.azurerm_network_watcher.this) == 1,
      data.azurerm_network_watcher.this[0].resource_group_name == "NetworkWatcherRG",
      !output.created,
      output.name == "NetworkWatcher_japaneast",
      output.id == data.azurerm_network_watcher.this[0].id,
    ])
    error_message = "The default must look up the exact existing watcher without creating or managing one."
  }
}

run "create_when_requested" {
  command = plan

  variables {
    create = true
    tags   = { environment = "test" }
  }

  assert {
    condition = alltrue([
      length(azurerm_network_watcher.this) == 1,
      length(data.azurerm_network_watcher.this) == 0,
      azurerm_network_watcher.this[0].name == "NetworkWatcher_japaneast",
      azurerm_network_watcher.this[0].resource_group_name == "NetworkWatcherRG",
      azurerm_network_watcher.this[0].location == "japaneast",
      azurerm_network_watcher.this[0].tags.environment == "test",
      output.created,
      output.name == "NetworkWatcher_japaneast",
      output.id == azurerm_network_watcher.this[0].id,
    ])
    error_message = "Opting in must create exactly one watcher with the requested name, region, and tags."
  }
}
