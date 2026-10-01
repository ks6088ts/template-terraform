variable "name" {
  description = "Lowercase UUID used as the Azure Workbook resource name"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.name))
    error_message = "name must be a lowercase UUID."
  }
}

variable "display_name" {
  description = "User-visible name of the Workbook"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Workbook"
  type        = string
}

variable "source_id" {
  description = "Source resource ID for the Workbook, normalized to lowercase as required by Azure"
  type        = string
}

variable "data_json" {
  description = "JSON configuration of the Workbook"
  type        = string

  validation {
    condition     = can(jsondecode(var.data_json))
    error_message = "data_json must contain valid JSON."
  }
}

variable "tags" {
  description = "Tags to apply to the Workbook"
  type        = map(string)
  default     = {}
}
