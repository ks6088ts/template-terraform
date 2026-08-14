variable "name" {
  description = "Base name for the Cosmos DB resources"
  type        = string
}

variable "account_name" {
  description = "Exact Cosmos DB account name; defaults to cosmos-{name}"
  type        = string
  default     = null

  validation {
    condition     = var.account_name == null || can(regex("^[a-z0-9][a-z0-9-]{1,42}[a-z0-9]$", coalesce(var.account_name, "")))
    error_message = "Cosmos DB account name must contain 3-44 lowercase letters, numbers, or hyphens and must begin and end with a letter or number."
  }
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

variable "capabilities" {
  description = "Capabilities enabled on the Cosmos DB account"
  type        = set(string)
  default = [
    "EnableNoSQLVectorSearch",
    "EnableServerless",
  ]
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for the Cosmos DB account"
  type        = bool
  default     = true
}

variable "local_authentication_enabled" {
  description = "Whether account keys can be used to authenticate to Cosmos DB"
  type        = bool
  default     = true
}

variable "minimal_tls_version" {
  description = "Minimum TLS version for the Cosmos DB account"
  type        = string
  default     = "Tls12"

  validation {
    condition     = var.minimal_tls_version == "Tls12"
    error_message = "Cosmos DB minimal TLS version must be Tls12."
  }
}

variable "consistency_level" {
  description = "Consistency level for Cosmos DB"
  type        = string
  default     = "BoundedStaleness"

  validation {
    condition     = contains(["BoundedStaleness", "ConsistentPrefix", "Eventual", "Session", "Strong"], var.consistency_level)
    error_message = "Cosmos DB consistency level must be BoundedStaleness, ConsistentPrefix, Eventual, Session, or Strong."
  }
}

variable "consistency_max_interval_in_seconds" {
  description = "Maximum staleness interval for Bounded Staleness consistency"
  type        = number
  default     = null
}

variable "consistency_max_staleness_prefix" {
  description = "Maximum stale request prefix for Bounded Staleness consistency"
  type        = number
  default     = null
}

variable "geo_locations" {
  description = "Geo-replicated locations; defaults to the primary module location"
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
  default = []

  validation {
    condition = length(var.geo_locations) == 0 || (
      contains([for geo in var.geo_locations : geo.failover_priority], 0) &&
      length(distinct([for geo in var.geo_locations : geo.failover_priority])) == length(var.geo_locations)
    )
    error_message = "Cosmos DB geo locations must include one priority 0 location and use unique failover priorities."
  }
}

variable "create_sql_database" {
  description = "Whether to create a Cosmos DB SQL database"
  type        = bool
  default     = true
}

variable "sql_database_name" {
  description = "SQL database name; defaults to cosmos-{name}-sqldb"
  type        = string
  default     = null
}

variable "create_sql_container" {
  description = "Whether to create a Cosmos DB SQL container"
  type        = bool
  default     = true
}

variable "sql_container_name" {
  description = "SQL container name; defaults to cosmos-{name}-sqlcontainer"
  type        = string
  default     = null
}

variable "partition_key_path" {
  description = "Single partition key path used when partition_key_paths is not set"
  type        = string
  default     = "/partitionKey"
}

variable "partition_key_paths" {
  description = "Partition key paths for the Cosmos DB SQL container"
  type        = list(string)
  default     = null

  validation {
    condition     = var.partition_key_paths == null || length(var.partition_key_paths) > 0
    error_message = "partition_key_paths must contain at least one path when set."
  }
}
