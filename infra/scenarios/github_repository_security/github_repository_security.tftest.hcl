mock_provider "github" {}

variables {
  github_owner = "example-org"
  repositories = {
    "new-repo" = {
      description = "New hardened repository"
      visibility  = "public"
      dependabot_ecosystems = [
        { package_ecosystem = "terraform", directory = "/infra" },
      ]
    }
    "existing-repo" = {
      create_repository = false
      codeql_workflow   = false
      team_permissions  = { "platform" = "maintain" }
      ruleset_bypass_actors = [
        { actor_id = 5, actor_type = "RepositoryRole" },
      ]
      ruleset_rules = {
        required_approving_review_count = 1
        required_status_checks          = [{ context = "test" }]
      }
    }
  }
}

run "harden_new_and_existing_repositories" {
  command = plan

  assert {
    condition = alltrue([
      keys(module.repository) == ["new-repo"],
      output.repositories["new-repo"].created,
      !output.repositories["existing-repo"].created,
    ])
    error_message = "Only repositories with create_repository = true must be created."
  }

  assert {
    condition = alltrue([
      output.repositories["new-repo"].dependabot,
      output.repositories["existing-repo"].dependabot,
      output.repositories["new-repo"].actions_policy,
      output.repositories["existing-repo"].ruleset == "default-branch-protection",
    ])
    error_message = "Dependabot, Actions policy, and ruleset must apply to every repository by default."
  }

  assert {
    condition = alltrue([
      length(output.repositories["new-repo"].security_files) == 5,
      contains(output.repositories["new-repo"].security_files, ".github/workflows/codeql.yml"),
      length(output.repositories["existing-repo"].security_files) == 3,
      !contains(output.repositories["existing-repo"].security_files, ".github/workflows/codeql.yml"),
    ])
    error_message = "Security files (repo-sec-004..009) must follow the per-repository toggles."
  }

  assert {
    condition = alltrue([
      output.repositories["existing-repo"].team_permissions == { "platform" = "maintain" },
      output.repositories["new-repo"].team_permissions == {},
    ])
    error_message = "Team access must only be managed when configured."
  }
}

run "opt_out_of_building_blocks" {
  command = plan

  variables {
    repositories = {
      "minimal-repo" = {
        create_repository      = false
        dependabot_enabled     = false
        ruleset_enabled        = false
        actions_policy_enabled = false
        security_policy_file   = false
        codeowners_file        = false
        dependabot_file        = false
        codeql_workflow        = false
      }
    }
  }

  assert {
    condition = alltrue([
      !output.repositories["minimal-repo"].dependabot,
      !output.repositories["minimal-repo"].actions_policy,
      output.repositories["minimal-repo"].ruleset == null,
      output.repositories["minimal-repo"].security_files == [],
    ])
    error_message = "Every building block must be optional per repository."
  }
}

run "reject_invalid_repository_name" {
  command = plan

  variables {
    repositories = {
      "invalid name" = {}
    }
  }

  expect_failures = [var.repositories]
}

run "default_inputs_manage_nothing" {
  command = plan

  variables {
    repositories = {}
  }

  assert {
    condition     = output.repositories == {}
    error_message = "The default inputs must not manage any repository."
  }
}
