# =============================================================================
# Resource Group Outputs
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

# =============================================================================
# Network Outputs
# =============================================================================

output "vnet_id" {
  description = "ID of the spoke VNet"
  value       = module.virtual_network.vnet_id
}

output "vnet_name" {
  description = "Name of the spoke VNet"
  value       = module.virtual_network.vnet_name
}

output "subnet_bastion_id" {
  description = "ID of the Bastion subnet"
  value       = module.virtual_network.subnet_ids["AzureBastionSubnet"]
}

output "subnet_paas_id" {
  description = "ID of the PaaS subnet"
  value       = module.virtual_network.subnet_ids["snet-paas-${var.name}"]
}

output "subnet_vm_id" {
  description = "ID of the VM subnet"
  value       = module.virtual_network.subnet_ids["snet-vm-${var.name}"]
}

# =============================================================================
# Storage Account Outputs
# =============================================================================

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage.account_id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.account_name
}

output "private_endpoint_blob_id" {
  description = "ID of the blob private endpoint"
  value       = module.storage.private_endpoint_id
}

output "private_endpoint_blob_ip" {
  description = "Private IP address of the blob private endpoint"
  value       = module.storage.private_endpoint_ip
}

# =============================================================================
# VM Outputs
# =============================================================================

output "vm_id" {
  description = "ID of the virtual machine"
  value       = module.linux_vm.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = module.linux_vm.name
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = module.linux_vm.private_ip
}

output "vm_admin_username" {
  description = "Admin username for the virtual machine"
  value       = module.linux_vm.admin_username
}

output "vm_ssh_private_key" {
  description = "SSH private key for the virtual machine (sensitive)"
  value       = module.linux_vm.ssh_private_key
  sensitive   = true
}

# =============================================================================
# Bastion Outputs
# =============================================================================

output "bastion_id" {
  description = "ID of the Azure Bastion"
  value       = module.bastion.id
}

output "bastion_name" {
  description = "Name of the Azure Bastion"
  value       = module.bastion.name
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion"
  value       = module.bastion.public_ip_address
}
