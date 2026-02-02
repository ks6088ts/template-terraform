variable "name" {
  description = "Base name for the Cosmos DB resources"
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

variable "consistency_level" {
  description = "Consistency level for Cosmos DB"
  type        = string
  default     = "BoundedStaleness"
}

variable "partition_key_path" {
  description = "Partition key path for Cosmos DB SQL container"
  type        = string
  default     = "/partitionKey"
}
