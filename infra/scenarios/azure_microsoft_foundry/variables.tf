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

variable "enable_standard_setup" {
  description = "Deploy the customer-managed data services and capability hosts required for Microsoft Foundry Standard setup"
  type        = bool
  default     = true
}

variable "enable_tracing" {
  description = "Enable server-side Foundry agent tracing with workspace-based Application Insights"
  type        = bool
  default     = false
}

variable "azure_ai_search_sku" {
  description = "SKU for the Azure AI Search service"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.azure_ai_search_sku)
    error_message = "Azure AI Search SKU must be one of: basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
  }
}

variable "operator_principal_id" {
  description = "Object ID of the principal that runs the Foundry IQ setup scripts; defaults to the Terraform client principal"
  type        = string
  default     = null
}

variable "enable_operator_cosmosdb_read_access" {
  description = "Grant the operator principal read-only access to inspect the Standard setup Cosmos DB account and enterprise_memory data"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_operator_cosmosdb_read_access || var.enable_standard_setup
    error_message = "enable_operator_cosmosdb_read_access = true requires enable_standard_setup = true."
  }
}

variable "model_deployments" {
  description = "Model deployments required by the Foundry IQ ingestion and prompt-agent workflow"
  type = list(object({
    format                 = optional(string, "OpenAI")
    name                   = string
    model                  = string
    version                = string
    sku_name               = optional(string, "GlobalStandard")
    capacity               = number
    version_upgrade_option = optional(string, "NoAutoUpgrade")
  }))
  default = [
    {
      name                   = "gpt-5.4-mini"
      model                  = "gpt-5.4-mini"
      version                = "2026-03-17"
      capacity               = 100
      version_upgrade_option = "NoAutoUpgrade"
    },
    {
      name                   = "text-embedding-3-large"
      model                  = "text-embedding-3-large"
      version                = "1"
      capacity               = 30
      version_upgrade_option = "NoAutoUpgrade"
    }
  ]
}
