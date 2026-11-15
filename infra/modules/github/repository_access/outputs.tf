output "team_permissions" {
  description = "Teams granted access to the repository and their permissions"
  value       = { for team, access in github_team_repository.this : team => access.permission }
}

output "deploy_key_titles" {
  description = "Titles of the read-only deploy keys"
  value       = keys(github_repository_deploy_key.this)
}
