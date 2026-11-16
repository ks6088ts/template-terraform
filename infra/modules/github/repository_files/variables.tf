variable "repository" {
  description = "Name of the repository"
  type        = string
}

variable "branch" {
  description = "Branch to commit to. null uses the default branch."
  type        = string
  default     = null
}

variable "files" {
  description = "File path to content map, for example SECURITY.md, .github/CODEOWNERS, .github/dependabot.yml (ghqr repo-sec-004..009)"
  type        = map(string)
  nullable    = false
  default     = {}
}

variable "commit_message_prefix" {
  description = "Prefix of the commit message; the file path is appended"
  type        = string
  nullable    = false
  default     = "chore: manage"
}

variable "overwrite_on_create" {
  description = "Overwrite files that already exist when they are first managed"
  type        = bool
  nullable    = false
  default     = false
}
