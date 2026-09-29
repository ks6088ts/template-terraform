variable "name" {
  description = "Specifies the base name for resources"
  type        = string
  default     = "azurecosmosdbplayground"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,25}[a-z0-9]$", var.name))
    error_message = "name must be 2-27 lowercase letters, digits, or hyphens, starting and ending with a letter or digit."
  }
}

variable "location" {
  description = "Azure region supporting serverless Cosmos DB and the selected Foundry models"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    scenario        = "azure_cosmosdb_playground"
    owner           = "ks6088ts"
    SecurityControl = "Ignore"
    CostControl     = "Ignore"
  }
}

variable "operator_principal_id" {
  description = "Entra object ID of the CLI operator; defaults to the Terraform identity"
  type        = string
  default     = null

  validation {
    condition     = var.operator_principal_id == null || can(regex("^[0-9a-fA-F-]{36}$", var.operator_principal_id))
    error_message = "operator_principal_id must be a UUID."
  }
}

variable "vector_dimensions" {
  description = "Embedding dimensions for the flat index (text-embedding-3-small supports 256)"
  type        = number
  default     = 256

  validation {
    condition     = var.vector_dimensions >= 1 && var.vector_dimensions <= 505 && floor(var.vector_dimensions) == var.vector_dimensions
    error_message = "Flat vector index dimensions must be an integer between 1 and 505."
  }
}

variable "embedding_model" {
  description = "Embedding model deployment; confirm version, capacity, and regional quota before apply"
  type = object({
    name     = string
    model    = string
    version  = string
    sku_name = string
    capacity = number
  })
  default = {
    name     = "text-embedding-3-small"
    model    = "text-embedding-3-small"
    version  = "1"
    sku_name = "GlobalStandard"
    capacity = 30
  }

  validation {
    condition     = var.embedding_model.capacity > 0 && var.embedding_model.model == "text-embedding-3-small" && length(var.embedding_model.name) > 0 && length(var.embedding_model.version) > 0 && length(var.embedding_model.sku_name) > 0
    error_message = "Embedding model must be text-embedding-3-small, with a name, version, SKU, and positive capacity."
  }
}

variable "chat_model" {
  description = "Answer model deployment; confirm version, capacity, and regional quota before apply"
  type = object({
    name     = string
    model    = string
    version  = string
    sku_name = string
    capacity = number
  })
  default = {
    name     = "gpt-5.4-mini"
    model    = "gpt-5.4-mini"
    version  = "2026-03-17"
    sku_name = "GlobalStandard"
    capacity = 100
  }

  validation {
    condition     = var.chat_model.capacity > 0 && length(var.chat_model.name) > 0 && var.chat_model.name != var.embedding_model.name && length(var.chat_model.model) > 0 && length(var.chat_model.version) > 0 && length(var.chat_model.sku_name) > 0
    error_message = "Chat model requires a distinct deployment name, model, version, SKU, and positive capacity."
  }
}
