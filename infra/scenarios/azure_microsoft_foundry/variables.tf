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
      name     = "text-embedding-3-large"
      model    = "text-embedding-3-large"
      version  = "1"
      capacity = 100
    },
    {
      name     = "text-embedding-3-small"
      model    = "text-embedding-3-small"
      version  = "1"
      capacity = 100
    }
  ]
}
