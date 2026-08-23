---
title: Cloud Cost Estimates with Infracost
description: Estimate Terraform costs locally and review cost changes in GitHub Actions
ms.date: 2026-08-23
ms.topic: how-to
---

## Install and authenticate

The development container installs the Infracost CLI and the Infracost VS Code
extension. Rebuild the container after pulling changes to
`.devcontainer/devcontainer.json`.

Outside the container, install the CLI for your platform:

```bash
# macOS
brew install infracost

# Linux
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Windows
choco install infracost
```

Then authenticate once and confirm the remaining development tools:

```bash
infracost auth login
make install-deps-dev
```

The CLI caches the resulting token, so local commands work without setting any
environment variable. Never commit a token or export it from a checked-in
script.

## Estimate costs locally

Run one command from the repository root to scan every detected project:

```bash
make cost
```

The target prints the scan summary, then a per-scenario listing with untruncated
project names and monthly costs. Scenarios without billable resources are
omitted from that listing. The listing is printed only for a whole-repository
scan, because a single-scenario scan already reports one total.

Limit the scan to a single scenario using the same `SCENARIO` variable as the
other targets, and pass CLI flags with `INFRACOST_ARGS`:

```bash
make cost SCENARIO=azure_container_apps
make cost INFRACOST_ARGS="--currency JPY"
```

Inspect the most recent scan without rescanning:

```bash
infracost inspect --failing
infracost inspect --top 10
```

## Interpret the results

Infracost parses Terraform code and retrieves pricing data. It does not require
cloud credentials, change Terraform state, or create cloud resources.

Treat the output as a design-time comparison, not an invoice forecast:

* Baseline costs assume a full month of operation, so a scenario that is
  deployed for an hour of evaluation costs a fraction of the reported amount.
* Usage costs depend on the usage defaults configured in Infracost Cloud or on
  an `infracost-usage.yml` file. This repository ships no usage file because its
  reported cost is dominated by baseline resources; add one when you need
  storage, function, or database request volumes reflected.
* Project detection is automatic. Add an `infracost.yml` only if detection is
  wrong, and re-measure afterwards, because a static project list overrides the
  automatic variable-file resolution and can silently lower both costs and
  policy findings.

The scenarios in this repository are reference implementations, not running
infrastructure. The most actionable output is therefore the FinOps and tagging
policy findings rather than the absolute monthly total. Existing findings are a
known backlog; when you touch a scenario, fix the findings it reports instead of
suppressing them.

## Review costs in GitHub Actions

The `.github/workflows/infracost.yml` workflow runs automatically when a pull
request from this repository is opened, updated, or reopened. It checks out the
pull request head, installs the pinned Infracost CLI, and runs the same
`make cost` command used locally. The `Estimate costs` step log contains the
repository-wide scan summary, FinOps and tagging findings, and monthly costs
grouped by scenario.

To run an estimate explicitly, select a branch in the Actions tab, or pass that
branch to the GitHub CLI:

```bash
gh workflow run infracost.yml --ref feature/example
```

The workflow does not run on pushes or closed pull requests. It reports the
estimate for the pull request head and does not maintain a default-branch
baseline or post a cost-difference comment.

The workflow downloads the pinned CLI release and verifies its official SHA-256
checksum before installing it. Review compatibility before updating
`INFRACOST_VERSION`.

Create the credential with the official setup flow, which issues a token of the
correct type for the current major version and stores it as a repository secret
named `INFRACOST_API_KEY`:

```bash
infracost ci setup --ci-pipeline
```

Tokens issued for Infracost CLI versions before 2.0 are not compatible. To set
the secret manually instead, this command prompts for the value and keeps it out
of shell history:

```bash
gh secret set INFRACOST_API_KEY
```

No AWS, Azure, or Google Cloud credentials are required. The workflow passes the
repository secret to the CLI through its supported non-interactive
authentication variable, and `make cost` sends the parsed cost data to
Infracost Cloud.

GitHub does not expose repository secrets or a write token to workflows
triggered by pull requests from forks or Dependabot, so the automatic job skips
them. After reviewing a Dependabot pull request, run the workflow manually on
its branch. Fork branches cannot be selected by `workflow_dispatch`, so check
out a reviewed fork locally and run `make cost` there. Infracost parses
Terraform code and does not run Terraform, but always review untrusted changes
before scanning them.

The workflow output is informational: it reports estimated costs and policy
findings in the Actions log but does not enforce a budget or post a pull request
comment. Use the Infracost GitHub App or a dedicated diff integration when you
need cost-difference comments and Cost Guardrail status checks.

Cost estimation is not part of `make ci-test`, because it requires the Infracost
credential. The `test` workflow covers credential-free static analysis
(`terraform fmt`, `terraform validate`, TFLint, Trivy, and actionlint), and the
`infracost` workflow covers cost review.

For local diagnostics, run:

```bash
infracost doctor
```

## Primary sources

* [Infracost: Get started](https://www.infracost.io/docs/)
* [Infracost CLI commands](https://www.infracost.io/docs/features/cli_commands/)
* [Infracost environment variables](https://www.infracost.io/docs/features/environment_variables/)
* [Infracost config file](https://www.infracost.io/docs/features/config_file/)
* [Infracost GitHub Actions guide](https://www.infracost.io/docs/integrations/github_actions/)
* [Official Infracost GitHub Actions](https://github.com/infracost/actions)
* [Infracost Cost Guardrails](https://www.infracost.io/docs/infracost_cloud/guardrails/)
* [Infracost usage costs](https://www.infracost.io/docs/features/usage_based_resources/)
* [Infracost security and privacy FAQ](https://www.infracost.io/docs/faq/#security-and-privacy)
