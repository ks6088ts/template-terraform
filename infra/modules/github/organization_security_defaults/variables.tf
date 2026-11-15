variable "billing_email" {
  description = "Billing email address of the organization (required by the GitHub API)"
  type        = string
  nullable    = false
}

variable "name" {
  description = "Display name of the organization. null keeps the provider default."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the organization. null keeps the provider default."
  type        = string
  default     = null
}

variable "default_repository_permission" {
  description = "Base permission for organization members (ghqr org-sec-003). admin is rejected."
  type        = string
  nullable    = false
  default     = "read"

  validation {
    condition     = contains(["none", "read", "write"], var.default_repository_permission)
    error_message = "default_repository_permission must be none, read, or write."
  }
}

variable "members_can_create_repositories" {
  description = "Whether members can create repositories"
  type        = bool
  nullable    = false
  default     = true
}

variable "members_can_create_public_repositories" {
  description = "Whether members can create public repositories (ghqr org-sec-004)"
  type        = bool
  nullable    = false
  default     = false
}

variable "members_can_create_private_repositories" {
  description = "Whether members can create private repositories"
  type        = bool
  nullable    = false
  default     = true
}

variable "members_can_create_public_pages" {
  description = "Whether members can publish public GitHub Pages sites"
  type        = bool
  nullable    = false
  default     = false
}

variable "members_can_fork_private_repositories" {
  description = "Whether members can fork private repositories"
  type        = bool
  nullable    = false
  default     = false
}

variable "web_commit_signoff_required" {
  description = "Require sign-off on web-based commits (ghqr org-sec-002)"
  type        = bool
  nullable    = false
  default     = true
}

variable "advanced_security_enabled_for_new_repositories" {
  description = "Enable GitHub Advanced Security for new repositories (ghqr org-def-006). Requires a GHAS license."
  type        = bool
  nullable    = false
  default     = false
}

variable "dependabot_alerts_enabled_for_new_repositories" {
  description = "Enable Dependabot alerts for new repositories (ghqr org-def-001)"
  type        = bool
  nullable    = false
  default     = true
}

variable "dependabot_security_updates_enabled_for_new_repositories" {
  description = "Enable Dependabot security updates for new repositories (ghqr org-def-002)"
  type        = bool
  nullable    = false
  default     = true
}

variable "dependency_graph_enabled_for_new_repositories" {
  description = "Enable the dependency graph for new repositories (ghqr org-def-003)"
  type        = bool
  nullable    = false
  default     = true
}

variable "secret_scanning_enabled_for_new_repositories" {
  description = "Enable secret scanning for new repositories (ghqr org-def-004)"
  type        = bool
  nullable    = false
  default     = true
}

variable "secret_scanning_push_protection_enabled_for_new_repositories" {
  description = "Enable secret scanning push protection for new repositories (ghqr org-def-005)"
  type        = bool
  nullable    = false
  default     = true
}
