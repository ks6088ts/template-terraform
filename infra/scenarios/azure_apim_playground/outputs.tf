output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "api_management_id" {
  description = "ID of the API Management instance"
  value       = module.api_management.id
}

output "api_management_name" {
  description = "Name of the API Management instance"
  value       = module.api_management.name
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management instance"
  value       = module.api_management.gateway_url
}

output "api_management_management_api_url" {
  description = "Management API URL of the API Management instance"
  value       = module.api_management.management_api_url
}

output "api_management_portal_url" {
  description = "Publisher portal URL of the API Management instance"
  value       = module.api_management.portal_url
}

output "api_management_developer_portal_url" {
  description = "Developer portal URL of the API Management instance"
  value       = module.api_management.developer_portal_url
}

output "core_api_id" {
  description = "ID of the self-contained playground API"
  value       = azurerm_api_management_api.core.id
}

output "core_api_url" {
  description = "Base URL of the versioned self-contained playground API"
  value       = "${trimsuffix(module.api_management.gateway_url, "/")}/${local.core_api_path}/${local.core_api_version}"
}

output "core_hello_url" {
  description = "URL of the core hello operation"
  value       = "${trimsuffix(module.api_management.gateway_url, "/")}/${local.core_api_path}/${local.core_api_version}/hello"
}

output "core_mock_url" {
  description = "URL of the core mock-response operation"
  value       = "${trimsuffix(module.api_management.gateway_url, "/")}/${local.core_api_path}/${local.core_api_version}/mock"
}

output "core_rate_limit_calls" {
  description = "Number of core API calls allowed in each renewal period"
  value       = var.core_rate_limit.calls
}

output "core_rate_limit_renewal_period_seconds" {
  description = "Core API rate-limit renewal period in seconds"
  value       = var.core_rate_limit.renewal_period_seconds
}

output "playground_product_id" {
  description = "ID of the APIM playground product"
  value       = azurerm_api_management_product.playground.id
}

output "playground_subscription_primary_key" {
  description = "Primary subscription key for the playground product"
  value       = random_password.subscription_primary_key.result
  sensitive   = true
}

output "playground_subscription_secondary_key" {
  description = "Secondary subscription key for the playground product"
  value       = random_password.subscription_secondary_key.result
  sensitive   = true
}

output "backend_pool_enabled" {
  description = "Whether deterministic Container Apps backends and the weighted APIM pool are enabled"
  value       = var.backend_pool != null
}

output "circuit_breaker_enabled" {
  description = "Whether the deterministic priority failover circuit breaker is enabled"
  value       = local.circuit_breaker_enabled
}

output "backend_urls" {
  description = "Direct URLs of the deterministic backend applications"
  value       = { for key, backend in azurerm_container_app.backend : key => "https://${backend.latest_revision_fqdn}" }
}

output "resilience_weighted_url" {
  description = "APIM endpoint that routes through the weighted backend pool"
  value       = var.backend_pool == null ? null : "${trimsuffix(module.api_management.gateway_url, "/")}/${local.resilience_api_path}/weighted"
}

output "resilience_failover_url" {
  description = "APIM endpoint that exercises priority failover, or null when the circuit breaker is disabled"
  value       = local.circuit_breaker_enabled ? "${trimsuffix(module.api_management.gateway_url, "/")}/${local.resilience_api_path}/failover" : null
}

output "weighted_backend_pool_id" {
  description = "ID of the weighted APIM backend pool"
  value       = var.backend_pool == null ? null : azapi_resource.weighted_pool[0].id
}

output "failover_backend_pool_id" {
  description = "ID of the priority failover APIM backend pool"
  value       = local.circuit_breaker_enabled ? azapi_resource.failover_pool[0].id : null
}

output "api_management_identity_principal_id" {
  description = "Principal ID of the API Management managed identity, or null when AI features are disabled"
  value       = module.api_management.identity_principal_id
}

output "operator_principal_id" {
  description = "Object ID of the principal that runs data-plane setup scripts"
  value       = local.operator_principal_id
}

output "ai_backend_enabled" {
  description = "Whether the OpenAI v1-compatible AI gateway API is enabled"
  value       = local.ai_enabled
}

output "ai_backend_mode" {
  description = "Ownership mode of the AI backend"
  value       = !local.ai_enabled ? null : (local.ai_provisioned ? "provision" : "existing")
}

output "ai_resource_id" {
  description = "Resource ID of the Azure AI account used by the gateway"
  value       = local.ai_resource_id
}

output "ai_backend_endpoint" {
  description = "OpenAI v1 data-plane endpoint used by the APIM backend"
  value       = local.ai_backend_url
}

output "ai_deployment_name" {
  description = "Model deployment name clients pass in the OpenAI model field"
  value       = local.ai_deployment_name
}

output "ai_gateway_url" {
  description = "OpenAI v1-compatible APIM gateway base URL"
  value       = local.ai_enabled ? "${trimsuffix(module.api_management.gateway_url, "/")}/ai/openai/v1" : null
}

output "llm_token_limit_enabled" {
  description = "Whether the LLM token limit policy is enabled"
  value       = var.llm_token_limit != null
}

output "content_safety_enabled" {
  description = "Whether the Azure AI Content Safety policy is enabled"
  value       = local.content_safety_enabled
}

output "content_safety_mode" {
  description = "Ownership mode of the Content Safety resource"
  value       = !local.content_safety_enabled ? null : (local.content_safety_provisioned ? "provision" : "existing")
}

output "content_safety_resource_id" {
  description = "Resource ID of the Azure AI Content Safety account"
  value       = local.content_safety_resource_id
}

output "content_safety_endpoint" {
  description = "Data-plane endpoint of the Azure AI Content Safety account"
  value       = local.content_safety_endpoint
}

output "content_safety_blocklist_name" {
  description = "Content Safety blocklist managed by the data-plane scripts"
  value       = local.content_safety_enabled ? var.content_safety.blocklist_name : null
}

output "observability_enabled" {
  description = "Whether Log Analytics and Application Insights observability is enabled"
  value       = local.observability_enabled
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace"
  value       = local.observability_enabled ? module.log_analytics[0].id : null
}

output "log_analytics_workspace_customer_id" {
  description = "Workspace ID used by Log Analytics data-plane queries"
  value       = local.observability_enabled ? module.log_analytics[0].workspace_id : null
}

output "application_insights_id" {
  description = "Resource ID of the Application Insights component"
  value       = local.observability_enabled ? module.application_insights[0].id : null
}

output "application_insights_app_id" {
  description = "Application ID used by Application Insights data-plane queries"
  value       = local.observability_enabled ? module.application_insights[0].app_id : null
}

output "llm_logging_enabled" {
  description = "Whether Azure Monitor LLM usage and optional message logging is enabled"
  value       = local.llm_logging_enabled
}

output "llm_token_metrics_enabled" {
  description = "Whether preview LLM token metrics are emitted to Application Insights"
  value       = local.token_metrics_enabled
}
