# =============================================================================
# Resource Group
# =============================================================================

module "resource_group" {
  source = "../../modules/azure/resource_group"

  name     = var.name
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Virtual Network and Subnets
# =============================================================================

module "virtual_network" {
  source = "../../modules/azure/virtual_network"

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  address_space       = var.vnet_address_space

  subnets = [
    {
      name             = "AzureBastionSubnet"
      address_prefixes = var.subnet_bastion_address_prefixes
    },
    {
      name                              = "snet-paas-${var.name}"
      address_prefixes                  = var.subnet_paas_address_prefixes
      private_endpoint_network_policies = "Disabled"
    },
    {
      name             = "snet-vm-${var.name}"
      address_prefixes = var.subnet_vm_address_prefixes
    }
  ]

  network_security_groups = [
    {
      name = "nsg-vm-${var.name}"
    }
  ]

  nsg_subnet_associations = [
    {
      subnet_name = "snet-vm-${var.name}"
      nsg_name    = "nsg-vm-${var.name}"
    }
  ]
}

# =============================================================================
# Storage Account with Private Endpoint
# =============================================================================

module "storage" {
  source = "../../modules/azure/storage_private"

  name                       = var.name
  resource_group_name        = module.resource_group.name
  resource_group_id          = module.resource_group.id
  location                   = module.resource_group.location
  tags                       = var.tags
  account_tier               = var.storage_account_tier
  account_replication_type   = var.storage_account_replication_type
  virtual_network_id         = module.virtual_network.vnet_id
  private_endpoint_subnet_id = module.virtual_network.subnet_ids["snet-paas-${var.name}"]
}

# =============================================================================
# Virtual Machine (Ubuntu)
# =============================================================================

module "linux_vm" {
  source = "../../modules/azure/linux_vm"

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  subnet_id           = module.virtual_network.subnet_ids["snet-vm-${var.name}"]
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  os_disk_size_gb     = var.vm_os_disk_size_gb
  os_disk_type        = var.vm_os_disk_type
}

# =============================================================================
# Azure Bastion
# =============================================================================

module "bastion" {
  source = "../../modules/azure/bastion"

  name                = var.name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  subnet_id           = module.virtual_network.subnet_ids["AzureBastionSubnet"]
  sku                 = var.bastion_sku
}
