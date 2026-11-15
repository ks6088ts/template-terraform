output "vulnerability_alerts_enabled" {
  description = "Whether Dependabot alerts are enabled"
  value       = github_repository_vulnerability_alerts.this.enabled
}

output "security_updates_enabled" {
  description = "Whether Dependabot security updates are enabled"
  value       = github_repository_dependabot_security_updates.this.enabled
}
