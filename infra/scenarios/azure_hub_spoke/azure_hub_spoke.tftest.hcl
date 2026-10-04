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

  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/networkInterfaces/nic-test"
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
      output.vm_network_interface_id == null,
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

run "private_vm_validates_blob_at_boot" {
  command = plan

  variables {
    enable_hub_spoke_peering        = true
    enable_private_endpoint_example = true
    enable_test_vm                  = true
  }

  assert {
    condition = alltrue([
      length(module.linux_vm) == 1,
      contains(keys(module.spoke_virtual_network.subnet_ids), "snet-workload"),
      length(module.spoke_virtual_network.subnet_ids) == 2,
      alltrue([for subnet in local.spoke_subnets : !subnet.default_outbound_access_enabled]),
      module.linux_vm[0].identity_principal_id == null,
      output.vm_network_interface_id == module.linux_vm[0].network_interface_id,
    ])
    error_message = "The test VM must use only private subnets, without default outbound access or a managed identity."
  }

  assert {
    condition = alltrue([
      yamldecode(local.validation_cloud_config).package_update == false,
      yamldecode(local.validation_cloud_config).package_upgrade == false,
      yamldecode(local.validation_cloud_config).write_files[0].content == file("${path.module}/scripts/validate_private_blob.sh"),
      strcontains(yamldecode(local.validation_cloud_config).write_files[1].content, "${module.storage[0].account_name}.blob.core.windows.net 10.1.1.4"),
      strcontains(yamldecode(local.validation_cloud_config).write_files[1].content, "TTYPath=/dev/ttyS0"),
      yamldecode(local.validation_cloud_config).runcmd[1] == ["systemctl", "enable", "--now", "validate-private-blob.service"],
    ])
    error_message = "Cloud-init must install the offline validation script and enable its serial-console service with the actual Blob host and PE IP."
  }
}

run "test_vm_requires_private_endpoint" {
  command = plan

  variables {
    enable_test_vm = true
  }

  expect_failures = [terraform_data.feature_dependencies]
}

run "vm_boot_diagnostics_and_custom_data" {
  command = plan

  module {
    source = "../../modules/azure/linux_vm"
  }

  variables {
    name                     = "test"
    resource_group_name      = "rg-test"
    location                 = "japaneast"
    subnet_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-workload"
    custom_data              = base64encode("#cloud-config\npackage_update: false\n")
    boot_diagnostics_enabled = true
  }

  assert {
    condition = alltrue([
      azurerm_linux_virtual_machine.this.custom_data == var.custom_data,
      length(azurerm_linux_virtual_machine.this.boot_diagnostics) == 1,
      azurerm_linux_virtual_machine.this.boot_diagnostics[0].storage_account_uri == null,
      azurerm_network_interface.this.ip_configuration[0].public_ip_address_id == null,
      azurerm_linux_virtual_machine.this.disable_password_authentication,
    ])
    error_message = "The VM must receive cloud-init and use managed boot diagnostics without a public IP or password authentication."
  }
}

run "vm_module_defaults" {
  command = plan

  module {
    source = "../../modules/azure/linux_vm"
  }

  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "japaneast"
    subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/snet-workload"
  }

  assert {
    condition = alltrue([
      azurerm_linux_virtual_machine.this.custom_data == null,
      length(azurerm_linux_virtual_machine.this.boot_diagnostics) == 0,
      length(azurerm_linux_virtual_machine.this.identity) == 0,
      azurerm_linux_virtual_machine.this.size == "Standard_B2s",
    ])
    error_message = "Shared VM module defaults must remain unchanged for callers without boot validation."
  }
}

run "private_subnet_has_no_default_outbound" {
  command = plan

  module {
    source = "../../modules/azure/virtual_network"
  }

  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "japaneast"
    address_space       = ["10.1.0.0/16"]
    subnets = [{
      name                            = "snet-workload"
      address_prefixes                = ["10.1.2.0/24"]
      default_outbound_access_enabled = false
    }]
  }

  assert {
    condition     = !azurerm_subnet.this["snet-workload"].default_outbound_access_enabled
    error_message = "The private subnet must explicitly disable default outbound access."
  }
}
