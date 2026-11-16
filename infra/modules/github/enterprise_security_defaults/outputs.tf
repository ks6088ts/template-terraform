output "id" {
  description = "ID of the enterprise security analysis settings"
  value       = github_enterprise_security_analysis_settings.this.id
}

output "enterprise_slug" {
  description = "Slug of the managed enterprise"
  value       = github_enterprise_security_analysis_settings.this.enterprise_slug
}

output "settings" {
  description = "Applied security defaults for new repositories"
  value = {
    advanced_security_enabled_for_new_repositories               = github_enterprise_security_analysis_settings.this.advanced_security_enabled_for_new_repositories
    secret_scanning_enabled_for_new_repositories                 = github_enterprise_security_analysis_settings.this.secret_scanning_enabled_for_new_repositories
    secret_scanning_push_protection_enabled_for_new_repositories = github_enterprise_security_analysis_settings.this.secret_scanning_push_protection_enabled_for_new_repositories
    secret_scanning_validity_checks_enabled                      = github_enterprise_security_analysis_settings.this.secret_scanning_validity_checks_enabled
  }
}
