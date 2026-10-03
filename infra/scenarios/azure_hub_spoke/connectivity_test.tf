resource "terraform_data" "feature_dependencies" {
  count = (var.enable_bastion || var.enable_nat_gateway) && !var.enable_test_vm ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.enable_test_vm
      error_message = "enable_test_vm must be true when enable_bastion or enable_nat_gateway is true."
    }
  }
}

module "linux_vm" {
  count  = var.enable_test_vm ? 1 : 0
  source = "../../modules/azure/linux_vm"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  subnet_id           = module.spoke_virtual_network.subnet_ids["snet-workload"]
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  os_disk_size_gb     = var.vm_os_disk_size_gb
  os_disk_type        = var.vm_os_disk_type
  identity_enabled    = var.vm_identity_enabled
}

module "bastion" {
  count  = var.enable_bastion ? 1 : 0
  source = "../../modules/azure/bastion"

  name                = local.resource_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = var.tags
  subnet_id           = module.spoke_virtual_network.subnet_ids["AzureBastionSubnet"]
  sku                 = var.bastion_sku
}

resource "azurerm_public_ip" "nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  name                = "pip-nat-${local.resource_name}"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  name                    = "nat-${local.resource_name}"
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

resource "azurerm_subnet_nat_gateway_association" "workload" {
  count = var.enable_nat_gateway ? 1 : 0

  subnet_id      = module.spoke_virtual_network.subnet_ids["snet-workload"]
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}
