---
title: Documentation
description: Entry point for shared Terraform guidance and deployable scenarios
ms.date: 2026-10-04
ms.topic: overview
---

## Get started

This repository deploys and destroys the Terraform root modules under
`infra/scenarios/`. Select a scenario from the
[repository README](../README.md), configure its provider credentials, and run
it with GNU Make or the Terraform CLI.

Start with the [shared prerequisites](tips/terraform-workflow.md#prerequisites)
to check tools, permissions, and network requirements. [Terraform Tips](tips/index.md)
contains procedures shared by every scenario.
Scenario READMEs contain resource-specific inputs, command overrides,
validation, and post-deployment operations.

## Shared guides

* [Prerequisites](tips/terraform-workflow.md#prerequisites)
* [Terraform workflow](tips/terraform-workflow.md)
* [Provider authentication](tips/provider-authentication.md)
* [Azure Blob Storage backend](tips/azure-blob-backend.md)
* [Cloud cost estimates with Infracost](tips/infracost.md)

## Scenario catalog

See the [repository README](../README.md) for all Azure, AWS, Google Cloud,
GitHub, and provider-independent scenarios.

## GitHub Copilot Agent Skills

In VS Code agent mode, describe the task or invoke a skill directly:

* [`/create-terraform-scenario`](../.github/skills/create-terraform-scenario/SKILL.md) creates a scenario and its documentation.
* [`/update-terraform-readme`](../.github/skills/update-terraform-readme/SKILL.md) updates scenario listings, diagrams, and procedures.

## References

* [Terraform documentation](https://developer.hashicorp.com/terraform/docs)
* [Terraform CLI installation](https://developer.hashicorp.com/terraform/install)
