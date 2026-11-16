output "repositories" {
  description = "Hardened repositories with the security building blocks applied to each"
  value = {
    for name, repository in var.repositories : name => {
      created          = repository.create_repository
      full_name        = "${var.github_owner}/${name}"
      dependabot       = contains(keys(module.repository_dependabot), name)
      actions_policy   = contains(keys(module.repository_actions_policy), name)
      ruleset          = try(module.repository_ruleset[name].name, null)
      security_files   = try(module.repository_files[name].files, [])
      team_permissions = try(module.repository_access[name].team_permissions, {})
    }
  }
}
