output "role_id" {
  description = "ID of the security_manager organization role"
  value       = github_organization_role_team.this.role_id
}

output "team_slug" {
  description = "Slug of the team assigned the security manager role"
  value       = github_organization_role_team.this.team_slug
}
