locals {
  created_repositories = { for name, repository in var.repositories : name => repository if repository.create_repository }

  # Existing repositories are referenced by name; created ones go through the module so dependencies are ordered.
  repository_names = {
    for name, repository in var.repositories : name => try(module.repository[name].name, name)
  }

  security_files = {
    for name, repository in var.repositories : name => {
      for path, file in {
        "SECURITY.md" = {
          enabled = repository.security_policy_file
          content = templatefile("${path.module}/templates/SECURITY.md.tftpl", {
            repository       = "${var.github_owner}/${name}"
            security_contact = repository.security_contact
          })
        }
        ".github/CODEOWNERS" = {
          enabled = repository.codeowners_file
          content = templatefile("${path.module}/templates/CODEOWNERS.tftpl", {
            owners = length(repository.codeowners) > 0 ? repository.codeowners : ["@${var.github_owner}"]
          })
        }
        ".github/dependabot.yml" = {
          enabled = repository.dependabot_file
          content = yamlencode({
            version = 2
            updates = [
              for ecosystem in concat(
                [{ package_ecosystem = "github-actions", directory = "/", interval = "weekly" }],
                repository.dependabot_ecosystems,
                ) : {
                package-ecosystem = ecosystem.package_ecosystem
                directory         = ecosystem.directory
                schedule          = { interval = ecosystem.interval }
              }
            ]
          })
        }
        ".github/workflows/codeql.yml" = {
          enabled = repository.codeql_workflow
          content = templatefile("${path.module}/templates/codeql.yml.tftpl", {
            default_branch = repository.default_branch
            languages      = repository.codeql_languages
          })
        }
        ".github/codeql/codeql-config.yml" = {
          enabled = repository.codeql_workflow
          content = yamlencode({
            name    = "ghqr security baseline"
            queries = [{ uses = "security-extended" }]
          })
        }
      } : path => file.content if file.enabled
    }
  }
}

module "repository" {
  source   = "../../modules/github/repository"
  for_each = local.created_repositories

  name                  = each.key
  description           = each.value.description
  visibility            = each.value.visibility
  topics                = each.value.topics
  has_issues            = each.value.has_issues
  has_discussions       = each.value.has_discussions
  security_and_analysis = each.value.manage_security_and_analysis ? each.value.security_and_analysis : null
}

module "repository_dependabot" {
  source   = "../../modules/github/repository_dependabot"
  for_each = { for name, repository in var.repositories : name => repository if repository.dependabot_enabled }

  repository = local.repository_names[each.key]
}

module "repository_actions_policy" {
  source   = "../../modules/github/repository_actions_policy"
  for_each = { for name, repository in var.repositories : name => repository if repository.actions_policy_enabled }

  repository             = local.repository_names[each.key]
  manage_allowed_actions = each.value.manage_allowed_actions
  allowed_actions_config = {
    patterns_allowed = each.value.actions_patterns
  }
}

module "repository_access" {
  source = "../../modules/github/repository_access"
  for_each = {
    for name, repository in var.repositories : name => repository
    if length(repository.team_permissions) + length(repository.deploy_keys) > 0
  }

  repository       = local.repository_names[each.key]
  team_permissions = each.value.team_permissions
  deploy_keys      = each.value.deploy_keys
}

module "repository_files" {
  source   = "../../modules/github/repository_files"
  for_each = { for name, repository in var.repositories : name => repository if length(local.security_files[name]) > 0 }

  repository          = local.repository_names[each.key]
  files               = local.security_files[each.key]
  overwrite_on_create = each.value.overwrite_files
}

# Commit the security files before the ruleset starts requiring pull requests.
module "repository_ruleset" {
  source   = "../../modules/github/repository_ruleset"
  for_each = { for name, repository in var.repositories : name => repository if repository.ruleset_enabled }

  repository    = local.repository_names[each.key]
  bypass_actors = each.value.ruleset_bypass_actors
  rules         = each.value.ruleset_rules

  depends_on = [module.repository_files]
}
