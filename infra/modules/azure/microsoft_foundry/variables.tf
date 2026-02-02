variable "name" {
  description = "Base name for the Microsoft Foundry resources"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "disable_local_auth" {
  description = "Disable local authentication (API Key) for the Cognitive Services account"
  type        = bool
  default     = false
}

variable "project_display_name" {
  description = "Display name for the Foundry project"
  type        = string
  default     = "project"
}

variable "project_description" {
  description = "Description for the Foundry project"
  type        = string
  default     = "My first project"
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
  default = []
}
