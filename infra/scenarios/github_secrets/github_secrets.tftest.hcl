mock_provider "github" {}

run "creates_environment_without_secrets" {
  command = plan

  assert {
    condition     = output.github_repository_environment_name == "dev"
    error_message = "The environment name output must use the default environment."
  }

  assert {
    condition     = length(module.repository_environment.secret_names) == 0
    error_message = "No environment secrets must be planned by default."
  }
}

run "creates_environment_secrets" {
  command = plan

  variables {
    repository_name  = "example-repo"
    environment_name = "staging"
    actions_environment_secrets = [
      { name = "API_KEY", value = "dummy-api-key" },
      { name = "DB_PASSWORD", value = "dummy-password" },
    ]
  }

  assert {
    condition     = output.github_repository_environment_name == "staging"
    error_message = "The environment name output must follow the environment_name variable."
  }

  assert {
    condition     = toset(module.repository_environment.secret_names) == toset(["API_KEY", "DB_PASSWORD"])
    error_message = "Each configured secret must be planned once by name."
  }
}
