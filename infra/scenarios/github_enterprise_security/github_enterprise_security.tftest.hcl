mock_provider "github" {}

variables {
  enterprise_slug = "example-enterprise"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = output.enterprise_slug == "example-enterprise"
    error_message = "The scenario must target the requested enterprise."
  }

  assert {
    condition = alltrue([
      output.security_defaults.advanced_security_enabled_for_new_repositories,
      output.security_defaults.secret_scanning_enabled_for_new_repositories,
      output.security_defaults.secret_scanning_push_protection_enabled_for_new_repositories,
      output.security_defaults.secret_scanning_validity_checks_enabled,
    ])
    error_message = "Defaults must satisfy ghqr ent-ghas-001..003."
  }
}

run "opt_out_of_advanced_security" {
  command = plan

  variables {
    advanced_security_enabled_for_new_repositories = false
  }

  assert {
    condition     = !output.security_defaults.advanced_security_enabled_for_new_repositories
    error_message = "Advanced Security must be optional for enterprises without a GHAS license."
  }
}

run "reject_invalid_enterprise_slug" {
  command = plan

  variables {
    enterprise_slug = "Example Enterprise"
  }

  expect_failures = [var.enterprise_slug]
}

run "no_enterprise_manages_nothing" {
  command = plan

  variables {
    enterprise_slug = null
  }

  assert {
    condition = alltrue([
      output.enterprise_slug == null,
      output.security_defaults == null,
    ])
    error_message = "Without enterprise_slug the scenario must not manage any enterprise."
  }
}
