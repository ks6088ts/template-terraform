# =============================================================================
# Resource Group Outputs
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.this.id
}

# =============================================================================
# Network Outputs
# =============================================================================

output "vnet_id" {
  description = "ID of the spoke VNet"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of the spoke VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "subnet_bastion_id" {
  description = "ID of the Bastion subnet"
  value       = azurerm_subnet.bastion.id
}

output "subnet_paas_id" {
  description = "ID of the PaaS subnet"
  value       = azurerm_subnet.paas.id
}

output "subnet_vm_id" {
  description = "ID of the VM subnet"
  value       = azurerm_subnet.vm.id
}

# =============================================================================
# Storage Account Outputs
# =============================================================================

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "private_endpoint_blob_id" {
  description = "ID of the blob private endpoint"
  value       = azurerm_private_endpoint.blob.id
}

output "private_endpoint_blob_ip" {
  description = "Private IP address of the blob private endpoint"
  value       = azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address
}

# =============================================================================
# VM Outputs
# =============================================================================

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_admin_username" {
  description = "Admin username for the virtual machine"
  value       = azurerm_linux_virtual_machine.this.admin_username
}

output "vm_ssh_private_key" {
  description = "SSH private key for the virtual machine (sensitive)"
  value       = tls_private_key.vm.private_key_pem
  sensitive   = true
}

# =============================================================================
# Bastion Outputs
# =============================================================================

output "bastion_id" {
  description = "ID of the Azure Bastion"
  value       = azurerm_bastion_host.this.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion"
  value       = azurerm_bastion_host.this.name
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = azurerm_public_ip.bastion.ip_address
}
