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
omitted from that listing.

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

The `.github/workflows/infracost.yml` workflow runs only when it is triggered
manually. Start it from the Actions tab, or with the GitHub CLI, passing the
pull request number to review:

```bash
gh workflow run infracost.yml -f pull_request_number=123
```

The workflow checks out that pull request and its base branch, then posts a
cost-difference comment. Manual triggering keeps cost review an explicit,
opt-in step instead of running on every push. The workflow deliberately does not
upload a repository-wide baseline, because these scenarios are not deployed and
such a baseline would report infrastructure that does not exist.

The action and the scanner version are both pinned, so a workflow run is
reproducible. Update `INFRACOST_SCANNER_VERSION` and the action commit together.

Create the credential with the official setup flow, which issues a token of the
correct type for the current major version and stores it as a repository secret
named `INFRACOST_API_KEY`:

```bash
infracost ci setup
```

Tokens issued for Infracost CLI versions before 2.0 are not compatible. To set
the secret manually instead, this command prompts for the value and keeps it out
of shell history:

```bash
gh secret set INFRACOST_API_KEY
```

No AWS, Azure, or Google Cloud credentials are required. The workflow does send
pull request metadata to Infracost Cloud, including the repository URL, pull
request number, title, author, and labels, alongside the parsed cost data.

Because a manually triggered run executes in this repository's context, the
credential is also available for pull requests from forks, so they can be
reviewed the same way. Infracost parses Terraform code and does not run
Terraform, but review fork changes before triggering a run.

The workflow reports cost and policy changes but does not enforce a budget, and
a manually triggered workflow cannot act as a required status check. To block
expensive changes automatically, create an Infracost Cost Guardrail with
approval before merge, and report the status through the Infracost GitHub App or
an automatically triggered workflow.

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
