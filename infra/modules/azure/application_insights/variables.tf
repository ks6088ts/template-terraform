variable "name" {
  description = "Base name for the Application Insights resource"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
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

variable "workspace_id" {
  description = "ID of the Log Analytics Workspace to back the (workspace-based) Application Insights resource"
  type        = string
}

variable "application_type" {
  description = "Type of Application Insights to create (e.g., web, java, MobileCenter, Node.JS, other)"
  type        = string
  default     = "web"

  validation {
    condition     = contains(["web", "java", "MobileCenter", "Node.JS", "other"], var.application_type)
    error_message = "application_type must be one of: web, java, MobileCenter, Node.JS, other."
  }
}

variable "sampling_percentage" {
  description = "Telemetry sampling percentage (0-100). 100 means no sampling."
  type        = number
  default     = 100

  validation {
    condition     = var.sampling_percentage >= 0 && var.sampling_percentage <= 100
    error_message = "sampling_percentage must be between 0 and 100."
  }
}
