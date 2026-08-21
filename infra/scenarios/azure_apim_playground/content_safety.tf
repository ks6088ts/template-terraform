locals {
  content_safety_provision_config = try(var.content_safety.provision, null)
  content_safety_existing_config  = try(var.content_safety.existing, null)
  content_safety_enabled          = var.content_safety != null
  content_safety_provisioned      = local.content_safety_provision_config != null
  content_safety_backend_name     = "playground-content-safety"

  content_safety_resource_id = local.content_safety_provisioned ? azurerm_cognitive_account.content_safety[0].id : try(
    local.content_safety_existing_config.resource_id,
    null,
  )
  content_safety_endpoint = local.content_safety_provisioned ? trimsuffix(azurerm_cognitive_account.content_safety[0].endpoint, "/") : try(
    trimsuffix(local.content_safety_existing_config.endpoint, "/"),
    null,
  )
  content_safety_categories = var.content_safety == null ? "" : join("", [
    for name, threshold in var.content_safety.categories :
    "<category name=\"${name}\" threshold=\"${threshold}\" />"
  ])
  content_safety_policy = var.content_safety == null ? "" : format(
    "<llm-content-safety backend-id=\"%s\" shield-prompt=\"%s\" enforce-on-completions=\"%s\"><categories output-type=\"EightSeverityLevels\">%s</categories><blocklists><id>%s</id></blocklists></llm-content-safety>",
    local.content_safety_backend_name,
    var.content_safety.shield_prompt,
    var.content_safety.enforce_on_completions,
    local.content_safety_categories,
    var.content_safety.blocklist_name,
  )
}

resource "azurerm_cognitive_account" "content_safety" {
  count = local.content_safety_provisioned ? 1 : 0

  name                          = "contentsafety${local.resource_suffix}"
  location                      = module.resource_group.location
  resource_group_name           = module.resource_group.name
  kind                          = "ContentSafety"
  sku_name                      = local.content_safety_provision_config.sku_name
  custom_subdomain_name         = "contentsafety${local.resource_suffix}"
  local_auth_enabled            = false
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_role_assignment" "apim_content_safety_user" {
  count = local.content_safety_enabled && local.ai_enabled ? 1 : 0

  scope                            = local.content_safety_resource_id
  role_definition_name             = "Cognitive Services User"
  principal_id                     = module.api_management.identity_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "operator_content_safety_user" {
  count = local.content_safety_enabled && local.ai_enabled ? 1 : 0

  scope                = local.content_safety_resource_id
  role_definition_name = "Cognitive Services User"
  principal_id         = local.operator_principal_id
}

resource "azapi_resource" "content_safety_backend" {
  count = local.content_safety_enabled && local.ai_enabled ? 1 : 0

  type      = "Microsoft.ApiManagement/service/backends@2024-06-01-preview"
  name      = local.content_safety_backend_name
  parent_id = module.api_management.id

  body = {
    properties = {
      type        = "Single"
      description = "Azure AI Content Safety backend secured with the API Management managed identity"
      protocol    = "http"
      url         = local.content_safety_endpoint
      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }
      tls = {
        validateCertificateChain = true
        validateCertificateName  = true
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [azurerm_role_assignment.apim_content_safety_user]
}
