output "id" {
  description = "ID of the organization settings resource"
  value       = github_organization_settings.this.id
}

output "default_repository_permission" {
  description = "Configured base permission for organization members"
  value       = github_organization_settings.this.default_repository_permission
}

output "settings" {
  description = "Applied organization security settings"
  value = {
    default_repository_permission                                = github_organization_settings.this.default_repository_permission
    members_can_create_public_repositories                       = github_organization_settings.this.members_can_create_public_repositories
    web_commit_signoff_required                                  = github_organization_settings.this.web_commit_signoff_required
    advanced_security_enabled_for_new_repositories               = github_organization_settings.this.advanced_security_enabled_for_new_repositories
    dependabot_alerts_enabled_for_new_repositories               = github_organization_settings.this.dependabot_alerts_enabled_for_new_repositories
    dependabot_security_updates_enabled_for_new_repositories     = github_organization_settings.this.dependabot_security_updates_enabled_for_new_repositories
    dependency_graph_enabled_for_new_repositories                = github_organization_settings.this.dependency_graph_enabled_for_new_repositories
    secret_scanning_enabled_for_new_repositories                 = github_organization_settings.this.secret_scanning_enabled_for_new_repositories
    secret_scanning_push_protection_enabled_for_new_repositories = github_organization_settings.this.secret_scanning_push_protection_enabled_for_new_repositories
  }
}
