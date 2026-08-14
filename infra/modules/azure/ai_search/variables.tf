variable "name" {
  description = "Name of the Azure AI Search service"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Azure AI Search service"
  type        = string
}

variable "sku" {
  description = "SKU for the Azure AI Search service"
  type        = string
  default     = "free"

  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.sku)
    error_message = "Azure AI Search SKU must be one of: free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
  }
}

variable "local_authentication_enabled" {
  description = "Whether API key authentication is enabled for the Azure AI Search service"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the Azure AI Search service"
  type        = map(string)
  default     = {}
}