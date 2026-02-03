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
  identity_enabled    = var.vm_identity_enabled
}

# =============================================================================
# NAT Gateway (Optional - for outbound internet connectivity)
# =============================================================================

resource "azurerm_public_ip" "nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "pip-nat-${var.name}"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  name                    = "nat-${var.name}"
  location                = module.resource_group.location
  resource_group_name     = module.resource_group.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
  zones                   = ["1"]
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[0].id
}

resource "azurerm_subnet_nat_gateway_association" "vm_subnet" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = module.virtual_network.subnet_ids["snet-vm-${var.name}"]
  nat_gateway_id = azurerm_nat_gateway.this[0].id
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
