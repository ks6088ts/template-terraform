mock_provider "github" {}

variables {
  name        = "example"
  description = "Example repository"
}

run "secure_defaults" {
  command = plan

  assert {
    condition = alltrue([
      github_repository.this.visibility == "private",
      github_repository.this.has_issues,
      github_repository.this.has_discussions,
      github_repository.this.delete_branch_on_merge,
      !github_repository.this.allow_merge_commit,
      github_repository.this.archive_on_destroy,
      github_repository.this.auto_init,
    ])
    error_message = "Repository defaults must satisfy ghqr repo-feat-001/002 and repo-comm-001."
  }

  assert {
    condition = alltrue([
      github_repository.this.security_and_analysis[0].secret_scanning[0].status == "enabled",
      github_repository.this.security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled",
      length(github_repository.this.security_and_analysis[0].advanced_security) == 0,
    ])
    error_message = "Secret scanning and push protection must be enabled by default without advanced_security."
  }
}

run "omit_security_and_analysis" {
  command = plan

  variables {
    security_and_analysis = null
  }

  assert {
    condition     = length(github_repository.this.security_and_analysis) == 0
    error_message = "security_and_analysis must be omitted when the object is null."
  }
}

run "reject_advanced_security_on_public" {
  command = plan

  variables {
    visibility            = "public"
    security_and_analysis = { advanced_security = "enabled" }
  }

  expect_failures = [github_repository.this]
}

run "reject_empty_description" {
  command = plan

  variables {
    description = " "
  }

  expect_failures = [var.description]
}
