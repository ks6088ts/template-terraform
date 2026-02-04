variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azurefuncflex"
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
    scenario        = "azure_functions_flex_consumption"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "runtime_name" {
  description = "The runtime for your app. One of: 'dotnet-isolated', 'python', 'java', 'node', 'powershell'"
  type        = string
  default     = "python"

  validation {
    condition     = contains(["dotnet-isolated", "python", "java", "node", "powershell"], var.runtime_name)
    error_message = "runtime_name must be one of: 'dotnet-isolated', 'python', 'java', 'node', 'powershell'."
  }
}

variable "runtime_version" {
  description = "The runtime version for your app. Depends on runtime_name."
  type        = string
  default     = "3.11"
}

variable "maximum_instance_count" {
  description = "The maximum instance count for the app (40-1000)"
  type        = number
  default     = 100

  validation {
    condition     = var.maximum_instance_count >= 40 && var.maximum_instance_count <= 1000
    error_message = "maximum_instance_count must be between 40 and 1000."
  }
}

variable "instance_memory_in_mb" {
  description = "The instance memory for the instances of the app: 512, 2048, or 4096"
  type        = number
  default     = 2048

  validation {
    condition     = contains([512, 2048, 4096], var.instance_memory_in_mb)
    error_message = "instance_memory_in_mb must be one of: 512, 2048, 4096."
  }
}

variable "zone_redundant" {
  description = "Whether the app is zone redundant or not"
  type        = bool
  default     = false
}

variable "app_settings" {
  description = "Additional app settings for the Function App"
  type        = map(string)
  default     = {}
}
