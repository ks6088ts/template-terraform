mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      name     = "rg-test"
      location = "japaneast"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
      name = "vnet-test"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/storageaccounttest"
      name = "storageaccounttest"
    }
  }

  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateEndpoints/pe-test"
      private_service_connection = {
        private_ip_address = "10.1.1.4"
      }
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
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

mock_provider "tls" {
  override_during = plan
}

run "default_is_two_vnets_only" {
  command = plan

  assert {
    condition = alltrue([
      length(azurerm_virtual_network_peering.hub_to_spoke) == 0,
      length(azurerm_virtual_network_peering.spoke_to_hub) == 0,
      length(module.storage) == 0,
      length(module.private_endpoint_blob) == 0,
      length(module.linux_vm) == 0,
      length(module.bastion) == 0,
      length(azurerm_nat_gateway.this) == 0,
      length(module.hub_virtual_network.subnet_ids) == 0,
      length(module.spoke_virtual_network.subnet_ids) == 0,
    ])
    error_message = "The default plan must contain only the resource group, hub VNet, and spoke VNet."
  }

  assert {
    condition = alltrue([
      output.hub_vnet_id == module.hub_virtual_network.vnet_id,
      output.spoke_vnet_id == module.spoke_virtual_network.vnet_id,
      output.hub_to_spoke_peering_id == null,
      output.storage_account_id == null,
      output.private_endpoint_blob_id == null,
      output.private_endpoint_blob_ip == null,
      output.vm_id == null,
      output.bastion_id == null,
      output.nat_gateway_id == null,
    ])
    error_message = "Disabled feature outputs must be null while both VNet outputs remain available."
  }
}

run "peering_is_bidirectional" {
  command = plan

  variables {
    enable_hub_spoke_peering = true
  }

  assert {
    condition = alltrue([
      length(azurerm_virtual_network_peering.hub_to_spoke) == 1,
      length(azurerm_virtual_network_peering.spoke_to_hub) == 1,
      azurerm_virtual_network_peering.hub_to_spoke[0].remote_virtual_network_id == module.spoke_virtual_network.vnet_id,
      azurerm_virtual_network_peering.spoke_to_hub[0].remote_virtual_network_id == module.hub_virtual_network.vnet_id,
      !azurerm_virtual_network_peering.hub_to_spoke[0].allow_gateway_transit,
      !azurerm_virtual_network_peering.spoke_to_hub[0].use_remote_gateways,
    ])
    error_message = "Enabling peering must create both safe, symmetric peering directions."
  }
}

run "private_endpoint_example_is_private" {
  command = plan

  variables {
    enable_private_endpoint_example = true
  }

  assert {
    condition = alltrue([
      length(module.storage) == 1,
      contains(keys(module.spoke_virtual_network.subnet_ids), "snet-private-endpoints"),
      length(module.private_endpoint_blob) == 1,
      module.private_endpoint_blob[0].id != null,
      output.private_endpoint_blob_id == module.private_endpoint_blob[0].id,
      output.private_endpoint_blob_ip == "10.1.1.4",
      output.storage_account_id == module.storage[0].account_id,
    ])
    error_message = "The example must add the dedicated subnet, private Storage account, and Blob private endpoint."
  }
}

run "connectivity_test_resources_are_opt_in" {
  command = plan

  variables {
    enable_test_vm     = true
    enable_bastion     = true
    enable_nat_gateway = true
  }

  assert {
    condition = alltrue([
      length(module.linux_vm) == 1,
      length(module.bastion) == 1,
      length(azurerm_nat_gateway.this) == 1,
      contains(keys(module.spoke_virtual_network.subnet_ids), "snet-workload"),
      contains(keys(module.spoke_virtual_network.subnet_ids), "AzureBastionSubnet"),
    ])
    error_message = "Connectivity test resources must be created only when their feature flags are enabled."
  }
}

run "bastion_requires_test_vm" {
  command = plan

  variables {
    enable_bastion = true
  }

  expect_failures = [terraform_data.feature_dependencies]
}

run "nat_gateway_requires_test_vm" {
  command = plan

  variables {
    enable_nat_gateway = true
  }

  expect_failures = [terraform_data.feature_dependencies]
}
