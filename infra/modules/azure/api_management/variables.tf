variable "name" {
  description = "Base name for the API Management instance"
  type        = string
}

variable "location" {
  description = "Azure region for the API Management instance"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
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

variable "tags" {
  description = "Tags to apply to the API Management instance"
  type        = map(string)
  default     = {}
}
