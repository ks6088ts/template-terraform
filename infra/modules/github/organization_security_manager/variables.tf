variable "team_slug" {
  description = "Slug of the team that receives the security manager role (ghqr org-sec-005). Used as the team name when create_team is true."
  type        = string

  validation {
    condition     = length(trimspace(var.team_slug)) > 0
    error_message = "team_slug must not be empty."
  }
}

variable "create_team" {
  description = "Create the team instead of using an existing one"
  type        = bool
  nullable    = false
  default     = false
}

variable "team_description" {
  description = "Description of the team when create_team is true"
  type        = string
  nullable    = false
  default     = "Security managers (managed by Terraform)"
}
