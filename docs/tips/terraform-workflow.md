---
title: Terraform Workflow
description: Run repository scenarios with GNU Make or the Terraform CLI
ms.date: 2026-10-04
ms.topic: how-to
---

## Prerequisites

### Local workstation tools

| Tool | When needed | Check |
|---|---|---|
| Git | Obtaining and updating the repository | `git --version` |
| Terraform CLI | Every scenario | `terraform version` |
| GNU Make | Following the `make` procedures | `make --version` |
| Bash | Running Bash commands or validation scripts from the README | `bash --version` |
| Azure CLI | Using Azure CLI authentication or inspecting resources with `az` | `az version` |
| Other CLIs and tools | When listed in the target scenario README | Follow the scenario instructions |

Check `required_version` in the target scenario's `versions.tf` for the
Terraform requirement. Test syntax can have additional version requirements;
use `TERRAFORM_VERSION` in [CI](../../.github/workflows/test.yml) as the baseline
for development and testing. Use the repository's provider constraints and
`.terraform.lock.hcl`. GNU Make is not required when using Terraform CLI directly.

For missing tools, follow the official installation guidance for
[Terraform CLI](https://developer.hashicorp.com/terraform/install),
[Git](https://git-scm.com/downloads), [GNU Make](https://www.gnu.org/software/make/),
and [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli).
Run the shell procedures in Bash. On Windows, use a Bash environment such as
WSL and ensure the required tools are executable from that environment.

### Authentication and permissions

Configure the relevant [provider authentication](provider-authentication.md)
and select the intended account, subscription, or project. After Azure CLI
authentication, check the subscription and confirm `state=Enabled`:

```bash
az account show --query '{subscription:id,name:name,tenant:tenantId,state:state}' -o table
```

Successful authentication does not prove deployment permissions. At minimum:

- You must be able to create, read, update, and delete the scenario resources
  at the target scope. Creating an Azure Resource Group also requires permission
  to create that group.
- Required Azure resource providers must be registered, or you must have
  permission to register them. Check the scenario's `providers.tf` for namespaces.
- Scenarios involving role assignments, Entra ID operations, or diagnostic
  retrieval require their additional permissions. Resource management permissions
  alone do not guarantee data-plane read/write access.
- A shared backend requires access to the state location.
  [Azure Blob Storage backend](azure-blob-backend.md) has separate authorization
  requirements.

If organizational policies prohibit required resources, choose a supported
configuration. Do not assume policies can be disabled or permissions and
features registered without approval.

### Network, capacity, and state

- The workstation must resolve DNS and reach Terraform Registry, provider
  distribution endpoints, and the relevant cloud APIs over HTTPS. Configure
  proxies and certificate requirements according to organizational guidance.
  Do not disable TLS certificate verification.
- Services and SKUs must be available in the selected region with sufficient
  subscription quotas and capacity. A listed SKU does not guarantee successful
  allocation.
- Check workload connectivity requirements in the scenario README. Workstation
  internet access and VM outbound connectivity are separate requirements.
- Review charges and the plan before provisioning. Successful authentication or
  planning does not establish deployment or data-plane connectivity success.
- If using local state, preserve the working directory securely. State, plans,
  and credentials can contain secrets; do not expose them in Git or logs.

### Development tool checks

For repository-wide development, linting, and cost estimation, run from the
repository root:

```bash
make install-deps-dev
```

This command checks for `terraform`, `az`, `gh`, `tflint`, `trivy`, `infracost`,
and `actionlint`. It reports missing tools and fails, but does not install them.
Not all of these tools are required to deploy an individual scenario.
Follow the scenario README's prerequisites for additional scenario-specific
requirements.

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
> `make clean SCENARIO="$SCENARIO"` removes only the `.terraform/` cache in the
> scenario directory. The tracked dependency lock file, local state, and variable
> files are preserved.

## Run a scenario with the Terraform CLI

Run direct Terraform commands from the scenario directory:

```bash
cd infra/scenarios/<scenario>

terraform init -lockfile=readonly
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

## Understand Azure resource names

Azure scenarios, except `azure_github_oidc`, treat the `name` variable as a
base name. On the first apply, each scenario generates one eight-character
lowercase alphanumeric suffix and reuses it for resources that can collide at
their Azure naming scope. For example, the base name `azurecontainerapps` can
produce `azurecontainerapps-a1b2c3d4`. Long base names are truncated when an
Azure service has a shorter name limit, but the suffix remains intact.

The generated suffix is stored in Terraform state and remains stable in later
plans and applies that use the same state. Azure-reserved names and selected
child names with independent fixed inputs remain unchanged. The
`azure_github_oidc` scenario is excluded so that its Entra and GitHub federation
display names remain stable.

> [!CAUTION]
> Deleting or losing state, replacing the `random_string` resource, or applying
> again after a destroy generates a different suffix. Because many Azure
> resource names are immutable, this can cause Terraform to replace resources.
> Preserve the state and review the plan before applying naming changes.

## Choose state storage

Terraform uses local state unless the root module declares another backend. Use
local state for isolated evaluation and repository tests. For shared or durable
state, follow the [Azure Blob Storage backend guide](azure-blob-backend.md).

Provider constraints and the tracked lock files are updated together. The Google
provider remains on the latest 7.x release (`7.46.1`) because Google provider 8
contains breaking changes; the OIDC scenario should be reviewed separately
before that major version is adopted.
