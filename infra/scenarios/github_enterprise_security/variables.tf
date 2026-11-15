variable "enterprise_slug" {
  description = "Slug of the GitHub Enterprise Cloud enterprise. null manages nothing."
  type        = string
  default     = null

  validation {
    condition     = var.enterprise_slug == null || can(regex("^[a-z0-9][a-z0-9-]*$", var.enterprise_slug))
    error_message = "enterprise_slug must be a lowercase enterprise slug."
  }
}

variable "advanced_security_enabled_for_new_repositories" {
  description = "Enable GitHub Advanced Security for new repositories (ghqr ent-ghas-001). Requires a GHAS license."
  type        = bool
  default     = true
}

variable "secret_scanning_enabled_for_new_repositories" {
  description = "Enable secret scanning for new repositories (ghqr ent-ghas-002)"
  type        = bool
  default     = true
}

variable "secret_scanning_push_protection_enabled_for_new_repositories" {
  description = "Enable secret scanning push protection for new repositories (ghqr ent-ghas-003)"
  type        = bool
  default     = true
}

variable "secret_scanning_push_protection_custom_link" {
  description = "Optional URL shown to users when push protection blocks a secret"
  type        = string
  default     = null
}

variable "secret_scanning_validity_checks_enabled" {
  description = "Enable validity checks for detected secrets"
  type        = bool
  default     = true
}
