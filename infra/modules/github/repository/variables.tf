variable "name" {
  description = "Name of the repository"
  type        = string
}

variable "description" {
  description = "Repository description (ghqr repo-meta-001)"
  type        = string

  validation {
    condition     = length(trimspace(var.description)) > 0
    error_message = "description must not be empty (ghqr repo-meta-001)."
  }
}

variable "visibility" {
  description = "Repository visibility: private, internal, or public"
  type        = string
  nullable    = false
  default     = "private"

  validation {
    condition     = contains(["private", "internal", "public"], var.visibility)
    error_message = "visibility must be private, internal, or public."
  }
}

variable "topics" {
  description = "Repository topics (ghqr repo-meta-002)"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "has_issues" {
  description = "Enable GitHub Issues (ghqr repo-feat-001)"
  type        = bool
  nullable    = false
  default     = true
}

variable "has_discussions" {
  description = "Enable GitHub Discussions (ghqr repo-comm-001)"
  type        = bool
  nullable    = false
  default     = true
}

variable "has_projects" {
  description = "Enable repository projects"
  type        = bool
  nullable    = false
  default     = false
}

variable "has_wiki" {
  description = "Enable the repository wiki"
  type        = bool
  nullable    = false
  default     = false
}

variable "allow_merge_commit" {
  description = "Allow merge commits. Keep false when the ruleset requires linear history."
  type        = bool
  nullable    = false
  default     = false
}

variable "allow_squash_merge" {
  description = "Allow squash merging"
  type        = bool
  nullable    = false
  default     = true
}

variable "allow_rebase_merge" {
  description = "Allow rebase merging"
  type        = bool
  nullable    = false
  default     = true
}

variable "delete_branch_on_merge" {
  description = "Automatically delete head branches after merge (ghqr repo-feat-002)"
  type        = bool
  nullable    = false
  default     = true
}

variable "web_commit_signoff_required" {
  description = "Require sign-off on web-based commits"
  type        = bool
  nullable    = false
  default     = true
}

variable "auto_init" {
  description = "Create an initial commit so the default branch exists for files and rulesets"
  type        = bool
  nullable    = false
  default     = true
}

variable "archive_on_destroy" {
  description = "Archive the repository instead of deleting it on destroy"
  type        = bool
  nullable    = false
  default     = true
}

variable "security_and_analysis" {
  description = "Security and analysis feature statuses (enabled/disabled). null omits a setting; set the whole object to null to leave security and analysis unmanaged. Private repositories need GitHub Advanced Security (Secret Protection / Code Security) licenses."
  type = object({
    advanced_security                     = optional(string)
    code_security                         = optional(string)
    secret_scanning                       = optional(string, "enabled")
    secret_scanning_push_protection       = optional(string, "enabled")
    secret_scanning_ai_detection          = optional(string)
    secret_scanning_non_provider_patterns = optional(string)
  })
  default = {}

  validation {
    condition = alltrue([
      for status in try(values(var.security_and_analysis), []) : status == null ? true : contains(["enabled", "disabled"], status)
    ])
    error_message = "security_and_analysis statuses must be enabled, disabled, or null."
  }
}
