---
title: Terraform Workflow
description: Run repository scenarios with GNU Make or the Terraform CLI
ms.date: 2026-08-13
ms.topic: how-to
---

## Prerequisites

Install the tools required by the target scenario, then configure the relevant
[provider authentication](provider-authentication.md). Check the development
commands available on your machine from the repository root:

```bash
make install-deps-dev
```

The command reports missing tools. It does not install them.

## Run a scenario with GNU Make

Set `SCENARIO` to a directory name under `infra/scenarios`. It defaults to
`hello_world` when omitted.

```bash
SCENARIO=azure_container_apps

make init SCENARIO="$SCENARIO"
make plan SCENARIO="$SCENARIO"
make deploy SCENARIO="$SCENARIO"
make output SCENARIO="$SCENARIO"
make destroy SCENARIO="$SCENARIO"
```

`make deploy` runs `terraform init` and then `terraform apply -auto-approve`.
It does not run the separate `make plan` target. Review a plan before deployment
when the change requires approval.

Additional development targets include:

```bash
make lint SCENARIO="$SCENARIO"
make test SCENARIO="$SCENARIO"
make fix SCENARIO="$SCENARIO"
```

For Azure scenarios, `make info` displays the active subscription and tenant.
The Makefile derives `ARM_SUBSCRIPTION_ID` from the current Azure CLI session and
exports it to Terraform commands.

> [!CAUTION]
> `make clean SCENARIO="$SCENARIO"` removes `.terraform*` and `terraform.*`
> files in the scenario directory. This includes local state and may include
> local variable files. Back up anything that must be retained before running
> it.

## Run a scenario with the Terraform CLI

Run direct Terraform commands from the scenario directory:

```bash
cd infra/scenarios/<scenario>

terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
terraform output
terraform destroy
```

AzureRM provider version 4 and later requires a subscription ID. When commands do not run
through the repository Makefile, export it after selecting the Azure
subscription:

```bash
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
```

Azure scenarios use AzureRM v5 with automatic resource provider registration
disabled. Each scenario explicitly registers only its required namespaces and
keeps location and resource provider validation enabled at plan time. Azure
Preflight Validation is not enabled.

The scenario README takes precedence when it specifies additional variables,
non-default flags, output checks, or post-deployment operations.

## Choose state storage

Terraform uses local state unless the root module declares another backend. Use
local state for isolated evaluation and repository tests. For shared or durable
state, follow the [Azure Blob Storage backend guide](azure-blob-backend.md).
