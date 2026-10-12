variable "catalog_name" {
  description = "Existing Unity Catalog catalog name; 1-255 ASCII letters, numbers, underscores, or hyphens, starting with a letter, number, or underscore"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_-]{0,254}$", var.catalog_name))
    error_message = "Catalog name must contain 1-255 ASCII letters, numbers, underscores, or hyphens and must not start with a hyphen."
  }
}

variable "name" {
  description = "Schema name; 1-255 ASCII letters, numbers, underscores, or hyphens, starting with a letter, number, or underscore"
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_][A-Za-z0-9_-]{0,254}$", var.name))
    error_message = "Schema name must contain 1-255 ASCII letters, numbers, underscores, or hyphens and must not start with a hyphen."
  }
}

variable "comment" {
  description = "Optional description of the schema"
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Delete the schema and all its contents on destroy; leave false to protect non-empty schemas"
  type        = bool
  default     = false
  nullable    = false
}
