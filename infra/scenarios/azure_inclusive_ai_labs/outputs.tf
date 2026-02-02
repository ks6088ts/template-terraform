output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.name
}

# azure_inclusive_ai_labs outputs
output "azure_inclusive_ai_labs_id" {
  description = "ID of the azure_inclusive_ai_labs Container App"
  value       = azurerm_container_app.azure_inclusive_ai_labs.id
}

output "azure_inclusive_ai_labs_name" {
  description = "Name of the azure_inclusive_ai_labs Container App"
  value       = azurerm_container_app.azure_inclusive_ai_labs.name
}

output "azure_inclusive_ai_labs_fqdn" {
  description = "FQDN of the azure_inclusive_ai_labs Container App (external URL)"
  value       = azurerm_container_app.azure_inclusive_ai_labs.ingress[0].fqdn
}

output "azure_inclusive_ai_labs_url" {
  description = "Full URL to access the azure_inclusive_ai_labs Container App"
  value       = "https://${azurerm_container_app.azure_inclusive_ai_labs.ingress[0].fqdn}"
}

# voicevox outputs
output "voicevox_id" {
  description = "ID of the voicevox Container App"
  value       = azurerm_container_app.voicevox.id
}

output "voicevox_name" {
  description = "Name of the voicevox Container App"
  value       = azurerm_container_app.voicevox.name
}

output "voicevox_internal_fqdn" {
  description = "Internal FQDN of the voicevox Container App (accessible only within the environment)"
  value       = azurerm_container_app.voicevox.ingress[0].fqdn
}

# Ollama outputs
output "ollama_id" {
  description = "ID of the Ollama Container App"
  value       = azurerm_container_app.ollama.id
}

output "ollama_name" {
  description = "Name of the Ollama Container App"
  value       = azurerm_container_app.ollama.name
}

output "ollama_internal_fqdn" {
  description = "Internal FQDN of the Ollama Container App (accessible only within the environment)"
  value       = azurerm_container_app.ollama.ingress[0].fqdn
}

output "ollama_url" {
  description = "URL to access the Ollama Container App (external URL if enabled, otherwise internal)"
  value       = var.ollama_external_enabled ? "https://${azurerm_container_app.ollama.ingress[0].fqdn}" : "http://app-ollama (internal only)"
}

output "ollama_external_enabled" {
  description = "Whether Ollama is accessible externally"
  value       = var.ollama_external_enabled
}

# Storage outputs
output "ollama_storage_account_name" {
  description = "Name of the Storage Account for Ollama"
  value       = azurerm_storage_account.ollama.name
}

output "ollama_storage_share_name" {
  description = "Name of the Azure File Share for Ollama"
  value       = azurerm_storage_share.ollama.name
}
