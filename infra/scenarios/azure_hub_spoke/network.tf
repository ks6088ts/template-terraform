locals {
  spoke_subnets = concat(
    var.enable_private_endpoint_example ? [{
      name                              = "snet-private-endpoints"
      address_prefixes                  = var.private_endpoint_subnet_address_prefixes
      private_endpoint_network_policies = "Disabled"
      default_outbound_access_enabled   = false
    }] : [],
    var.enable_test_vm ? [{
      name                              = "snet-workload"
      address_prefixes                  = var.workload_subnet_address_prefixes
      private_endpoint_network_policies = null
      default_outbound_access_enabled   = false
    }] : []
  )
}

module "hub_virtual_network" {
  source = "../../modules/azure/virtual_network"

  name                = "hub-${local.resource_name}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  address_space       = var.hub_vnet_address_space
}

module "spoke_virtual_network" {
  source = "../../modules/azure/virtual_network"

  name                = "spoke-${local.resource_name}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  address_space       = var.spoke_vnet_address_space
  subnets             = local.spoke_subnets

  network_security_groups = var.enable_test_vm ? [{
    name = "nsg-workload-${local.resource_name}"
  }] : []

  nsg_subnet_associations = var.enable_test_vm ? [{
    subnet_name = "snet-workload"
    nsg_name    = "nsg-workload-${local.resource_name}"
  }] : []
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count = var.enable_hub_spoke_peering ? 1 : 0

  name                         = "peer-hub-to-spoke"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.hub_virtual_network.vnet_name
  remote_virtual_network_id    = module.spoke_virtual_network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.enable_hub_spoke_peering ? 1 : 0

  name                         = "peer-spoke-to-hub"
  resource_group_name          = module.resource_group.name
  virtual_network_name         = module.spoke_virtual_network.vnet_name
  remote_virtual_network_id    = module.hub_virtual_network.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
