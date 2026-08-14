variable "name" {
  description = "Specifies the name"
  type        = string
  default     = "azuremicrosoftfoundry"
}

variable "location" {
  description = "Specifies the location"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Specifies the tags"
  type        = map(string)
  default = {
    scenario        = "azure_microsoft_foundry"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "deploy_standard_agent" {
  description = "Deploy the resources required for a standard Microsoft Foundry agent"
  type        = bool
  default     = false
}

variable "azure_ai_search_sku" {
  description = "SKU for the Azure AI Search service"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.azure_ai_search_sku)
    error_message = "Azure AI Search SKU must be one of: standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
  }
}

variable "operator_principal_id" {
  description = "Object ID of the principal that runs the Foundry IQ setup scripts; defaults to the Terraform client principal"
  type        = string
  default     = null
}

variable "model_deployments" {
  description = "Specifies the model deployments for Azure AI Foundry"
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
      name     = "gpt-5.6-luna"
      model    = "gpt-5.6-luna"
      version  = "2026-07-09"
      capacity = 1000
    },
    {
      name     = "gpt-5.6-terra"
      model    = "gpt-5.6-terra"
      version  = "2026-07-09"
      capacity = 1000
    },
    {
      name     = "gpt-5.6-sol"
      model    = "gpt-5.6-sol"
      version  = "2026-07-09"
      capacity = 1000
    },
    {
      name     = "gpt-5.4-mini"
      model    = "gpt-5.4-mini"
      version  = "2026-03-17"
      capacity = 1000
    },
    {
      name     = "text-embedding-3-large"
      model    = "text-embedding-3-large"
      version  = "1"
      capacity = 3000
    },
    {
      name     = "text-embedding-3-small"
      model    = "text-embedding-3-small"
      version  = "1"
      capacity = 3000
    }
  ]
}
