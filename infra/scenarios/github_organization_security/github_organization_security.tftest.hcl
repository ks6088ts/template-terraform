mock_provider "github" {
  mock_data "github_organization_roles" {
    defaults = {
      roles = [
        {
          role_id     = 138
          name        = "security_manager"
          description = "Security manager"
          source      = "Predefined"
          base_role   = "read"
          permissions = []
        },
        {
          role_id     = 8132
          name        = "all_repo_read"
          description = "Read all repositories"
          source      = "Predefined"
          base_role   = "read"
          permissions = []
        },
      ]
    }
  }
}

variables {
  organization  = "example-org"
  billing_email = "billing@example.com"
}

run "secure_defaults" {
  command = plan

  assert {
    condition = alltrue([
      output.security_defaults.default_repository_permission == "read",
      !output.security_defaults.members_can_create_public_repositories,
      output.security_defaults.web_commit_signoff_required,
      !output.security_defaults.advanced_security_enabled_for_new_repositories,
      output.security_defaults.dependabot_alerts_enabled_for_new_repositories,
      output.security_defaults.dependabot_security_updates_enabled_for_new_repositories,
      output.security_defaults.dependency_graph_enabled_for_new_repositories,
      output.security_defaults.secret_scanning_enabled_for_new_repositories,
      output.security_defaults.secret_scanning_push_protection_enabled_for_new_repositories,
    ])
    error_message = "Defaults must satisfy ghqr org-def-001..005 and org-sec-002..004 without requiring GHAS."
  }

  assert {
    condition = alltrue([
      output.actions_default_workflow_permissions == "read",
      output.actions_allowed_actions == "selected",
    ])
    error_message = "The Actions policy must satisfy ghqr org-act-001..003."
  }

  assert {
    condition = alltrue([
      output.security_manager_team_slug == null,
      output.organization_ruleset_name == null,
    ])
    error_message = "Optional security manager and organization ruleset must be disabled by default."
  }
}

run "security_manager_and_ruleset" {
  command = plan

  variables {
    security_manager_team = {
      slug = "security-managers"
    }
    enable_organization_ruleset = true
    organization_ruleset = {
      enforcement   = "evaluate"
      bypass_actors = [{ actor_type = "OrganizationAdmin", actor_id = 1, bypass_mode = "always" }]
      rules = {
        required_status_checks = [{ context = "ci" }]
      }
    }
  }

  assert {
    condition = alltrue([
      output.security_manager_team_slug == "security-managers",
      module.organization_security_manager[0].role_id == 138,
    ])
    error_message = "The security_manager role must be assigned to the team (ghqr org-sec-005)."
  }

  assert {
    condition     = output.organization_ruleset_name == "org-default-branch-protection"
    error_message = "The organization ruleset must use the module default name."
  }
}

run "create_security_manager_team" {
  command = plan

  variables {
    security_manager_team = {
      slug   = "security-managers"
      create = true
    }
  }

  assert {
    condition     = module.organization_security_manager[0].role_id == 138
    error_message = "A created team must also receive the security_manager role."
  }
}

run "settings_overrides" {
  command = plan

  variables {
    security_defaults = {
      advanced_security_enabled_for_new_repositories = true
    }
    actions_policy = {
      patterns_allowed     = ["hashicorp/setup-terraform@*"]
      sha_pinning_required = true
    }
  }

  assert {
    condition = alltrue([
      output.security_defaults.advanced_security_enabled_for_new_repositories,
      output.security_defaults.default_repository_permission == "read",
    ])
    error_message = "Overrides must merge with the module defaults."
  }
}

run "disable_everything" {
  command = plan

  variables {
    billing_email            = null
    enable_security_defaults = false
    enable_actions_policy    = false
  }

  assert {
    condition = alltrue([
      output.security_defaults == null,
      output.actions_allowed_actions == null,
    ])
    error_message = "Each building block must be optional."
  }
}

run "reject_admin_base_permission" {
  command = plan

  variables {
    security_defaults = {
      default_repository_permission = "admin"
    }
  }

  expect_failures = [var.security_defaults]
}

run "no_organization_manages_nothing" {
  command = plan

  variables {
    organization                = null
    billing_email               = null
    security_manager_team       = { slug = "security-managers" }
    enable_organization_ruleset = true
  }

  assert {
    condition = alltrue([
      output.security_defaults == null,
      output.actions_allowed_actions == null,
      output.security_manager_team_slug == null,
      output.organization_ruleset_name == null,
    ])
    error_message = "Without organization the scenario must not manage any organization setting."
  }
}
