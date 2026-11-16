variable "repository" {
  description = "Name of the repository"
  type        = string
}

variable "team_permissions" {
  description = "Team slug (or ID) to permission map. Grant access through teams instead of direct collaborators (ghqr repo-acc-001/002)."
  type        = map(string)
  nullable    = false
  default     = {}

  validation {
    condition     = alltrue([for permission in values(var.team_permissions) : length(trimspace(permission)) > 0])
    error_message = "team_permissions values must not be empty (use pull, triage, push, maintain, admin, or a custom role name)."
  }
}

variable "deploy_keys" {
  description = "Deploy key title to public key map. Keys are always read-only (ghqr repo-acc-003); prefer GitHub Apps or OIDC (repo-acc-005)."
  type        = map(string)
  nullable    = false
  default     = {}
}
