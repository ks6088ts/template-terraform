---
description: Harden GitHub repositories against the ghqr repository recommendations with Terraform
---

# GitHub Repository Security

This scenario applies the repository-scope recommendations reported by
`ghqr list-recommendations --scope repository` to one or more repositories.
Each repository in the `repositories` map gets the same reusable building blocks,
which can be turned off individually.

- `create_repository = true` creates the repository with security and analysis settings.
- `create_repository = false` hardens an existing repository without managing
  `github_repository` itself.

## Architecture

```mermaid
flowchart LR
    Vars["repositories map"] --> Scenario["github_repository_security"]
    Scenario -->|"create_repository = true"| Repo["github/repository<br/>settings and security_and_analysis"]
    Scenario --> Dependabot["github/repository_dependabot<br/>alerts and security updates"]
    Scenario --> Actions["github/repository_actions_policy<br/>GITHUB_TOKEN and allowed actions"]
    Scenario --> Access["github/repository_access<br/>teams and read-only deploy keys"]
    Scenario --> Files["github/repository_files<br/>SECURITY.md, CODEOWNERS,<br/>dependabot.yml, CodeQL"]
    Files -->|"commit before"| Ruleset["github/repository_ruleset<br/>default branch ruleset"]
```

The ruleset depends on the committed files because it requires pull requests
on the default branch after it is created.

## ghqr rule mapping

| ghqr | Setting | Module |
|------|---------|--------|
| repo-bp-001, repo-bp-014 | Ruleset on `~DEFAULT_BRANCH` with `active` enforcement | `repository_ruleset` |
| repo-bp-002, 003, 006 | Pull requests with 2 approving reviews | `repository_ruleset` |
| repo-bp-004, 005 | Dismiss stale reviews, require code owner review | `repository_ruleset` |
| repo-bp-007..009 | Strict required status checks (set `ruleset_rules.required_status_checks`) | `repository_ruleset` |
| repo-bp-010..013 | Block force pushes and deletion, require signed commits and linear history | `repository_ruleset` |
| repo-sec-001 | Dependabot alerts | `repository_dependabot` |
| repo-sec-007 | Dependabot security updates and `dependabot.yml` | `repository_dependabot`, `repository_files` |
| repo-sec-004 | `SECURITY.md` | `repository_files` |
| repo-sec-005 | `.github/CODEOWNERS` | `repository_files` |
| repo-sec-006 | `.github/dependabot.yml` (`github-actions` plus `dependabot_ecosystems`) | `repository_files` |
| repo-sec-008 | `.github/workflows/codeql.yml` | `repository_files` |
| repo-sec-009 | `.github/codeql/codeql-config.yml` (`security-extended` queries) | `repository_files` |
| repo-acc-001, 002 | Access through `team_permissions` instead of direct collaborators | `repository_access` |
| repo-acc-003..005 | Deploy keys are always read-only; prefer GitHub Apps or OIDC | `repository_access` |
| repo-feat-001, repo-comm-001 | Issues and Discussions enabled | `repository` |
| repo-feat-002 | Delete head branches on merge | `repository` |
| repo-meta-001, 002 | Description and topics | `repository` |
| (GHAS) | Secret scanning and push protection | `repository` |
| (org-act-001..003 at repository level) | Read-only `GITHUB_TOKEN`, selected actions only | `repository_actions_policy` |

The provider cannot configure repo-sec-002, repo-sec-003 (open Dependabot alerts),
or repo-meta-003 (dormant repositories). Resolve them operationally.
CodeQL default setup is not supported by the provider, so this scenario commits
an advanced setup workflow instead.

## Prerequisites

- Meet the prerequisites of the [Terraform workflow](../../../docs/tips/terraform-workflow.md).
- Configure `GITHUB_TOKEN` by following [provider authentication](../../../docs/tips/provider-authentication.md#github).
  A classic token needs the `repo` and `workflow` scopes (the latter to commit the CodeQL workflow).
  `team_permissions` on organization repositories also needs `read:org`.
- Public repositories get secret scanning and CodeQL at no cost. Private and internal
  repositories need GitHub Secret Protection and Code Security licenses; otherwise set
  `manage_security_and_analysis = false` and `codeql_workflow = false`.
- The default ruleset requires 2 approvals, code owner review, and signed commits.
  Lower `ruleset_rules.required_approving_review_count` for repositories with fewer maintainers.

## How to use

Create `infra/scenarios/github_repository_security/terraform.tfvars`.
The file is ignored by Git.
The following example applies the strictest settings this scenario supports to a public repository.

```hcl
github_owner = "your-org-or-user"

# A single maintainer cannot satisfy 2 approvals and code owner review, so pull requests cannot be merged.
# Relax ruleset_rules or ruleset_bypass_actors to fit your workflow.
repositories = {
  "secure-sample" = {
    create_repository = true
    description       = "Public repository hardened with the strictest ghqr baseline"
    visibility        = "public"
    topics            = ["security", "terraform"]
    has_issues        = true
    has_discussions   = true

    # advanced_security and code_security cannot be set on public repositories (always enabled).
    # Non-provider patterns and AI detection need GitHub Secret Protection, so they are omitted.
    manage_security_and_analysis = true
    security_and_analysis = {
      secret_scanning                 = "enabled"
      secret_scanning_push_protection = "enabled"
    }

    # Dependabot alerts, security updates, and scheduled github-actions updates
    dependabot_enabled = true
    dependabot_file    = true
    # Add the ecosystems used by the repository (for example { package_ecosystem = "pip", directory = "/" }).
    dependabot_ecosystems = []

    # CodeQL with security-extended queries. Add languages as code is added (for example "python").
    codeql_workflow  = true
    codeql_languages = ["actions"]

    # Default branch ruleset without bypass actors
    ruleset_enabled       = true
    ruleset_bypass_actors = []
    ruleset_rules = {
      required_approving_review_count   = 2
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_review_thread_resolution = true
      # GitHub cannot rebase merge when signed commits are required, so allow squash only.
      allowed_merge_methods = ["squash"]
      # Add "Analyze (<language>)" for each language in codeql_languages.
      required_status_checks               = [{ context = "Analyze (actions)" }]
      strict_required_status_checks_policy = true
      required_code_scanning = [{
        tool                      = "CodeQL"
        alerts_threshold          = "all"
        security_alerts_threshold = "all"
      }]
      non_fast_forward        = true
      deletion                = true
      required_signatures     = true
      required_linear_history = true
    }

    # Read-only GITHUB_TOKEN; only GitHub-owned and verified creator actions are allowed.
    actions_policy_enabled = true
    manage_allowed_actions = true
    actions_patterns       = []

    # Teams are organization-only. No deploy keys are created.
    team_permissions = {}
    deploy_keys      = {}

    # SECURITY.md (links to private vulnerability reporting when the contact is null) and CODEOWNERS
    security_policy_file = true
    security_contact     = null
    codeowners_file      = true
    codeowners           = ["@your-org-or-user"]

    overwrite_files = false
  }
}
```

Then run from the repository root:

```bash
export GITHUB_TOKEN=$(gh auth token)
make init SCENARIO=github_repository_security
make plan SCENARIO=github_repository_security
make deploy SCENARIO=github_repository_security
```

Verify the result with ghqr:

```bash
./ghqr scan -r your-org-or-user/secure-sample
```

### Notes

- `create_repository = false` leaves `security_and_analysis`, description, and topics unmanaged.
  To manage them, import the repository with `terraform import 'module.repository["<name>"].github_repository.this' <name>`
  and set `create_repository = true`.
- Existing files are not overwritten unless `overwrite_files = true`.
- After the ruleset exists, later Terraform file updates must bypass it.
  Add a bypass actor such as `{ actor_id = 5, actor_type = "RepositoryRole", bypass_mode = "always" }` (repository admin)
  only if you accept that trade-off.
- `repository_actions_policy` manages the repository allowed actions policy. Set
  `manage_allowed_actions = false` when an organization policy already restricts actions.
- Destroying a created repository archives it instead of deleting it.

## Troubleshooting

### `404 Not Found` when committing `.github/workflows/codeql.yml`

```text
Error: PUT https://api.github.com/repos/<owner>/<repo>/contents/.github/workflows/codeql.yml: 404 Not Found []
```

GitHub returns `404` instead of `403` when the token lacks the `workflow` scope, which is required to
create or update files under `.github/workflows/`. Add the scope, export the token again, and rerun
`make deploy`. The ruleset is created after the files, so the rerun completes the deployment.

```bash
gh auth refresh -h github.com -s workflow
export GITHUB_TOKEN=$(gh auth token)
```

### `422 Secret scanning is not available for this repository`

```text
Error: PATCH https://api.github.com/repos/<owner>/<repo>: 422 Secret scanning is not available for this repository. []
```

`visibility` defaults to `private`, and private repositories need a GitHub Secret Protection license
for secret scanning. Settings are not shared between entries in `repositories`, so set
`visibility = "public"` on each repository that should be public. Otherwise set
`manage_security_and_analysis = false` and `codeql_workflow = false`.

### `404 Not Found` while refreshing a repository deleted outside Terraform

```text
Error: repository doesn't exist anymore, please remove the resource from your configuration: GET https://api.github.com/repos/<owner>/<repo>: 404 Not Found []
Error: GET https://api.github.com/repos/<owner>/<repo>/actions/permissions: 404 Not Found []
```

The state still references a repository that GitHub cannot return. GitHub also returns `404` when
the token cannot access a repository, so first check it with `gh repo view <owner>/<repo>`.
If the repository was deleted, back up the state, remove the resources of that repository from the state,
and run `make plan` to recreate it.

```bash
dir=infra/scenarios/github_repository_security
terraform -chdir="$dir" state pull > github_repository_security.tfstate.bak
terraform -chdir="$dir" state list | grep -F '["<repo>"]' | while IFS= read -r address; do
  terraform -chdir="$dir" state rm "$address"
done
```

## Variables

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `github_owner` | `string` | GitHub user or organization that owns the repositories | `"ks6088ts"` |
| `repositories` | `map(object)` | Repositories keyed by name; see the attributes below | `{}` |

Main `repositories` attributes (omitted values use the module defaults):

| Attribute | Default | Description |
|-----------|---------|-------------|
| `create_repository` | `true` | Create the repository, or harden an existing one |
| `default_branch` | `"main"` | Branch that triggers CodeQL on push |
| `description`, `topics` | baseline text, `["security", "terraform"]` | Repository metadata |
| `visibility` | `private` | `private`, `internal`, or `public` |
| `manage_security_and_analysis`, `security_and_analysis` | `true`, secret scanning and push protection enabled | GHAS feature statuses |
| `dependabot_enabled` | `true` | Dependabot alerts and security updates |
| `ruleset_enabled`, `ruleset_rules`, `ruleset_bypass_actors` | `true`, secure defaults, `[]` | Default branch ruleset |
| `actions_policy_enabled`, `manage_allowed_actions`, `actions_patterns` | `true`, `true`, `[]` | Read-only token and selected actions |
| `team_permissions`, `deploy_keys` | `{}` | Team access and read-only deploy keys |
| `security_policy_file`, `security_contact` | `true`, `null` | `SECURITY.md`; private vulnerability reporting link when no contact |
| `codeowners_file`, `codeowners` | `true`, `["@<github_owner>"]` | `.github/CODEOWNERS` |
| `dependabot_file`, `dependabot_ecosystems` | `true`, `[]` | `.github/dependabot.yml` |
| `codeql_workflow`, `codeql_languages` | `true`, `["actions"]` | CodeQL workflow and config |
| `overwrite_files` | `false` | Overwrite existing files on first management |

## Outputs

| Name | Description |
|------|-------------|
| `repositories` | Per repository: whether it was created, full name, and the building blocks applied |

## Offline tests

The scenario and module tests use a mock GitHub provider and `command = plan`.
They need no credentials and make no GitHub API calls.

```bash
export TF_DATA_DIR=$(mktemp -d)
terraform -chdir=infra/scenarios/github_repository_security init -backend=false -lockfile=readonly -input=false
terraform -chdir=infra/scenarios/github_repository_security validate
terraform -chdir=infra/scenarios/github_repository_security test
```

The `test-github-mock` job in [CI](../../../.github/workflows/test.yml) runs the same
checks and the `repository` and `repository_ruleset` module tests.
This scenario is not part of the live `test-github` job because it creates repositories.
