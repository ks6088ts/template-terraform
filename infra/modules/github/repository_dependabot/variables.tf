variable "repository" {
  description = "Name of the repository"
  type        = string
}

variable "vulnerability_alerts_enabled" {
  description = "Enable Dependabot alerts (ghqr repo-sec-001)"
  type        = bool
  nullable    = false
  default     = true
}

variable "security_updates_enabled" {
  description = "Enable Dependabot security updates (ghqr repo-sec-007). Requires vulnerability alerts."
  type        = bool
  nullable    = false
  default     = true
}
