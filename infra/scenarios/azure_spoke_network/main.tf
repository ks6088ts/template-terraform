# =============================================================================
# Resource Group
# =============================================================================

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name}"
  location = var.location
  tags     = var.tags
}

# =============================================================================
# Virtual Network and Subnets
# =============================================================================

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Bastion Subnet (must be named "AzureBastionSubnet")
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = var.subnet_bastion_address_prefixes
}

# PaaS Subnet (for Private Endpoints)
resource "azurerm_subnet" "paas" {
  name                              = "snet-paas-${var.name}"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.spoke.name
  address_prefixes                  = var.subnet_paas_address_prefixes
  private_endpoint_network_policies = "Disabled"
}

# VM Subnet
resource "azurerm_subnet" "vm" {
  name                 = "snet-vm-${var.name}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = var.subnet_vm_address_prefixes
}

# =============================================================================
# Network Security Groups
# =============================================================================

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-vm-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# =============================================================================
# Storage Account with Private Endpoint
# =============================================================================

resource "azurerm_storage_account" "this" {
  name                          = substr("sa${replace(var.name, "-", "")}${substr(md5(azurerm_resource_group.this.id), 0, 8)}", 0, 24)
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  account_tier                  = var.storage_account_tier
  account_replication_type      = var.storage_account_replication_type
  public_network_access_enabled = false
  tags                          = var.tags
}

# Private DNS Zone for Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-blob-${var.name}"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = var.tags
}

# Private Endpoint for Blob Storage
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.paas.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob-${var.name}"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdz-blob-${var.name}"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

# =============================================================================
# Virtual Machine (Ubuntu)
# =============================================================================

# Generate SSH Key
resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Network Interface for VM
resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Ubuntu Virtual Machine
resource "azurerm_linux_virtual_machine" "this" {
  name                            = "vm-${var.name}"
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm.public_key_openssh
  }

  os_disk {
    name                 = "osdisk-vm-${var.name}"
    caching              = "ReadWrite"
    storage_account_type = var.vm_os_disk_type
    disk_size_gb         = var.vm_os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

# =============================================================================
# Azure Bastion
# =============================================================================

resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = "bas-${var.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.bastion_sku
  tags                = var.tags

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}
