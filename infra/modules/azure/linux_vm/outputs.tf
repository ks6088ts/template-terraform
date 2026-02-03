output "id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.this.private_ip_address
}

output "admin_username" {
  description = "Admin username for the virtual machine"
  value       = azurerm_linux_virtual_machine.this.admin_username
}

output "ssh_private_key" {
  description = "SSH private key for the virtual machine"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key for the virtual machine"
  value       = tls_private_key.this.public_key_openssh
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.this.id
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity"
  value       = var.identity_enabled ? azurerm_linux_virtual_machine.this.identity[0].principal_id : null
}
