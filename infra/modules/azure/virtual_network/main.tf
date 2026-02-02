# Virtual Network
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                              = each.value.name
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = each.value.address_prefixes
  private_endpoint_network_policies = lookup(each.value, "private_endpoint_network_policies", null)
}

# Network Security Groups
resource "azurerm_network_security_group" "this" {
  for_each = { for nsg in var.network_security_groups : nsg.name => nsg }

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# NSG to Subnet Associations
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for assoc in var.nsg_subnet_associations : assoc.subnet_name => assoc }

  subnet_id                 = azurerm_subnet.this[each.value.subnet_name].id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_name].id
}
