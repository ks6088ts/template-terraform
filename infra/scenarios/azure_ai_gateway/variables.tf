variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azureaigateway"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    scenario        = "azure_ai_gateway"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "publisher_name" {
  description = "Publisher name for API Management"
  type        = string
  default     = "Example Organization"
}

variable "publisher_email" {
  description = "Publisher email for API Management"
  type        = string
  default     = "admin@example.com"
}

variable "gateway_api_path" {
  description = "Public API path segment exposed by API Management for Azure OpenAI requests"
  type        = string
  default     = "openai"

  validation {
    condition     = length(var.gateway_api_path) > 0 && !startswith(var.gateway_api_path, "/") && !endswith(var.gateway_api_path, "/")
    error_message = "gateway_api_path must be a non-empty relative path without leading or trailing slashes."
  }
}

variable "openai_api_version" {
  description = "Azure OpenAI data-plane API version added by the API Management policy when callers omit api-version"
  type        = string
  default     = "2024-10-21"
}

variable "model_deployments" {
  description = "Specifies the model deployments for the Microsoft Foundry account"
  type = list(object({
    format   = optional(string, "OpenAI")
    name     = string
    model    = string
    version  = string
    sku_name = optional(string, "GlobalStandard")
    capacity = number
  }))
  default = [
    {
      name     = "gpt-5.4-mini"
      model    = "gpt-5.4-mini"
      version  = "2026-03-17"
      capacity = 1000
    }
  ]
}
