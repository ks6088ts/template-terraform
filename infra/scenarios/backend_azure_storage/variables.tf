variable "name" {
  description = "Specifies the name"
  type        = string
  default     = "backendazurestorage"
}

variable "location" {
  description = "Specifies the location"
  type        = string
  default     = "japaneast"
}

variable "tags" {
  description = "Specifies the tags"
  type        = map(any)
  default = {
    scenario        = "backend_azure_storage"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}
