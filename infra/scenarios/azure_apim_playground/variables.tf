variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azureapimplayground"
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
    scenario        = "azure_apim_playground"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "publisher_name" {
  description = "Publisher name for the API Management instance"
  type        = string
  default     = "Example Organization"
}

variable "publisher_email" {
  description = "Publisher email for the API Management instance"
  type        = string
  default     = "admin@example.com"
}

variable "sku_name" {
  description = "SKU tier and capacity for API Management; Consumption_0 keeps this playground serverless and usage-based"
  type        = string
  default     = "Consumption_0"
}
