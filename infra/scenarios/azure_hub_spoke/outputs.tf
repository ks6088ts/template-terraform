output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "hub_vnet_id" {
  description = "ID of the hub VNet"
  value       = module.hub_virtual_network.vnet_id
}

output "hub_vnet_name" {
  description = "Name of the hub VNet"
  value       = module.hub_virtual_network.vnet_name
}

output "spoke_vnet_id" {
  description = "ID of the spoke VNet"
  value       = module.spoke_virtual_network.vnet_id
}

output "spoke_vnet_name" {
  description = "Name of the spoke VNet"
  value       = module.spoke_virtual_network.vnet_name
}

output "hub_to_spoke_peering_id" {
  description = "ID of the hub-to-spoke peering, or null when disabled"
  value       = var.enable_hub_spoke_peering ? azurerm_virtual_network_peering.hub_to_spoke[0].id : null
}

output "spoke_to_hub_peering_id" {
  description = "ID of the spoke-to-hub peering, or null when disabled"
  value       = var.enable_hub_spoke_peering ? azurerm_virtual_network_peering.spoke_to_hub[0].id : null
}

output "private_endpoint_subnet_id" {
  description = "ID of the Private Endpoint subnet, or null when the example is disabled"
  value       = var.enable_private_endpoint_example ? module.spoke_virtual_network.subnet_ids["snet-private-endpoints"] : null
}

output "workload_subnet_id" {
  description = "ID of the test VM subnet, or null when the VM and NAT Gateway are disabled"
  value       = var.enable_test_vm || var.enable_nat_gateway ? module.spoke_virtual_network.subnet_ids["snet-workload"] : null
}

output "bastion_subnet_id" {
  description = "ID of AzureBastionSubnet, or null when Bastion is disabled"
  value       = var.enable_bastion ? module.spoke_virtual_network.subnet_ids["AzureBastionSubnet"] : null
}

output "storage_account_id" {
  description = "ID of the example storage account, or null when disabled"
  value       = var.enable_private_endpoint_example ? module.storage[0].account_id : null
}

output "storage_account_name" {
  description = "Name of the example storage account, or null when disabled"
  value       = var.enable_private_endpoint_example ? module.storage[0].account_name : null
}

output "private_endpoint_blob_id" {
  description = "ID of the Blob private endpoint, or null when disabled"
  value       = var.enable_private_endpoint_example ? module.private_endpoint_blob[0].id : null
}

output "private_endpoint_blob_ip" {
  description = "Private IP address of the Blob private endpoint, or null when disabled"
  value       = var.enable_private_endpoint_example ? module.private_endpoint_blob[0].private_ip_address : null
}

output "vm_id" {
  description = "ID of the test VM, or null when disabled"
  value       = var.enable_test_vm ? module.linux_vm[0].id : null
}

output "vm_name" {
  description = "Name of the test VM, or null when disabled"
  value       = var.enable_test_vm ? module.linux_vm[0].name : null
}

output "vm_private_ip" {
  description = "Private IP address of the test VM, or null when disabled"
  value       = var.enable_test_vm ? module.linux_vm[0].private_ip : null
}

output "vm_admin_username" {
  description = "Admin username for the test VM, or null when disabled"
  value       = var.enable_test_vm ? module.linux_vm[0].admin_username : null
}

output "vm_ssh_private_key" {
  description = "SSH private key for the test VM, or null when disabled"
  value       = var.enable_test_vm ? module.linux_vm[0].ssh_private_key : null
  sensitive   = true
}

output "vm_identity_principal_id" {
  description = "Principal ID of the test VM managed identity, or null when disabled"
  value       = var.enable_test_vm ? module.linux_vm[0].identity_principal_id : null
}

output "bastion_id" {
  description = "ID of Azure Bastion, or null when disabled"
  value       = var.enable_bastion ? module.bastion[0].id : null
}

output "bastion_name" {
  description = "Name of Azure Bastion, or null when disabled"
  value       = var.enable_bastion ? module.bastion[0].name : null
}

output "bastion_public_ip" {
  description = "Public IP address of Azure Bastion, or null when disabled"
  value       = var.enable_bastion ? module.bastion[0].public_ip_address : null
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway, or null when disabled"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.this[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway, or null when disabled"
  value       = var.enable_nat_gateway ? azurerm_public_ip.nat_gateway[0].ip_address : null
}
