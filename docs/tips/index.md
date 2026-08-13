---
title: Terraform Tips
description: Shared Terraform workflows, provider authentication, and remote state guidance for every scenario
ms.date: 2026-08-13
ms.topic: overview
---

## Guides

Use these guides for setup and operations that are shared across scenarios:

* [Terraform workflow](terraform-workflow.md)
* [Provider authentication](provider-authentication.md)
* [Azure Blob Storage backend](azure-blob-backend.md)

Scenario READMEs contain only the inputs, command overrides, validation, and
post-deployment operations that are specific to that scenario.

## State storage

Terraform uses the local backend when a scenario does not contain a `backend`
block. The local backend is suitable for individual evaluation and for this
repository's automated tests.

Use the [Azure Blob Storage backend](azure-blob-backend.md) when state needs to
be shared or persisted outside the working directory. This repository keeps the
AWS S3 example in the
[AWS GitHub OIDC scenario](../../infra/scenarios/aws_github_oidc/README.md) and
the Google Cloud Storage example in the
[Google GitHub OIDC scenario](../../infra/scenarios/google_github_oidc/README.md).
