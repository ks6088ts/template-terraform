mock_provider "github" {}

variables {
  repository = "example"
}

run "secure_defaults" {
  command = plan

  assert {
    condition = alltrue([
      github_repository_ruleset.this.target == "branch",
      github_repository_ruleset.this.enforcement == "active",
      github_repository_ruleset.this.conditions[0].ref_name[0].include == tolist(["~DEFAULT_BRANCH"]),
    ])
    error_message = "The ruleset must actively protect the default branch (repo-bp-001)."
  }

  assert {
    condition = alltrue([
      github_repository_ruleset.this.rules[0].pull_request[0].required_approving_review_count == 2,
      github_repository_ruleset.this.rules[0].pull_request[0].dismiss_stale_reviews_on_push,
      github_repository_ruleset.this.rules[0].pull_request[0].require_code_owner_review,
      github_repository_ruleset.this.rules[0].non_fast_forward,
      github_repository_ruleset.this.rules[0].deletion,
      github_repository_ruleset.this.rules[0].required_signatures,
      github_repository_ruleset.this.rules[0].required_linear_history,
    ])
    error_message = "Default rules must satisfy ghqr repo-bp-002..013."
  }

  assert {
    condition = alltrue([
      length(github_repository_ruleset.this.rules[0].required_status_checks) == 0,
      length(github_repository_ruleset.this.rules[0].required_code_scanning) == 0,
      length(github_repository_ruleset.this.bypass_actors) == 0,
    ])
    error_message = "Optional blocks must be omitted when not configured."
  }
}

run "status_checks_and_code_scanning" {
  command = plan

  variables {
    bypass_actors = [{ actor_id = 5, actor_type = "RepositoryRole" }]
    rules = {
      required_status_checks = [{ context = "test" }, { context = "lint" }]
      required_code_scanning = [{}]
    }
  }

  assert {
    condition = alltrue([
      length(github_repository_ruleset.this.rules[0].required_status_checks[0].required_check) == 2,
      github_repository_ruleset.this.rules[0].required_status_checks[0].strict_required_status_checks_policy,
      one(github_repository_ruleset.this.rules[0].required_code_scanning[0].required_code_scanning_tool).tool == "CodeQL",
      github_repository_ruleset.this.bypass_actors[0].bypass_mode == "pull_request",
    ])
    error_message = "Status checks (repo-bp-007..009), code scanning, and bypass actors must be rendered."
  }
}

run "reject_too_many_reviews" {
  command = plan

  variables {
    rules = { required_approving_review_count = 11 }
  }

  expect_failures = [var.rules]
}
