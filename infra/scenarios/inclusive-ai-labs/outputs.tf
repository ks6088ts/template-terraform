output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.name
}

# inclusive-ai-labs outputs
output "inclusive_ai_labs_id" {
  description = "ID of the inclusive-ai-labs Container App"
  value       = azurerm_container_app.inclusive_ai_labs.id
}

output "inclusive_ai_labs_name" {
  description = "Name of the inclusive-ai-labs Container App"
  value       = azurerm_container_app.inclusive_ai_labs.name
}

output "inclusive_ai_labs_fqdn" {
  description = "FQDN of the inclusive-ai-labs Container App (external URL)"
  value       = azurerm_container_app.inclusive_ai_labs.ingress[0].fqdn
}

output "inclusive_ai_labs_url" {
  description = "Full URL to access the inclusive-ai-labs Container App"
  value       = "https://${azurerm_container_app.inclusive_ai_labs.ingress[0].fqdn}"
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
