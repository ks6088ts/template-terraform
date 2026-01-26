# inclusive-ai-labs

This Terraform scenario deploys the inclusive-ai-labs application on Azure Container Apps with the following components:

- **inclusive-ai-labs**: Main API server (externally accessible)
- **voicevox**: Text-to-speech engine (internal only, used by inclusive-ai-labs)

## Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │           Container Apps Environment                │
                    │                                                     │
 Internet ──────────┼──► app-inclusive-ai-labs (port 8000)               │
                    │           │                                         │
                    │           │ HTTP (internal)                         │
                    │           ▼                                         │
                    │       app-voicevox (port 50021)                     │
                    │       [internal only]                               │
                    └─────────────────────────────────────────────────────┘
```

## Prerequisites

- Azure subscription
- Terraform >= 1.6.0
- Azure CLI (logged in)
- Azure OpenAI resource with deployed model

## Quick Start

1. **Initialize Terraform**

   ```bash
   terraform init
   ```

2. **Create a `terraform.tfvars` file**

   ```hcl
   name     = "inclusiveailabs"
   location = "japaneast"

   # Azure OpenAI Settings (required)
   genai_azure_openai_endpoint = "https://your-openai-resource.openai.azure.com/"
   genai_azure_openai_api_key  = "your-api-key-here"
   genai_azure_openai_deployment_name = "gpt-4o"
   ```

3. **Deploy**

   ```bash
   terraform plan
   terraform apply
   ```

4. **Access the application**

   After deployment, the URL will be shown in the outputs:

   ```bash
   terraform output inclusive_ai_labs_url
   ```

## Variables

### Required Variables

| Name | Description |
|------|-------------|
| `genai_azure_openai_api_key` | Azure OpenAI API key (sensitive) |

### Optional Variables

| Name | Default | Description |
|------|---------|-------------|
| `name` | `inclusiveailabs` | Base name for resources |
| `location` | `japaneast` | Azure region |
| `inclusive_ai_labs_image` | `ks6088ts/inclusive-ai-labs:0.0.3` | Docker image |
| `inclusive_ai_labs_cpu` | `2.0` | CPU cores |
| `inclusive_ai_labs_memory` | `4Gi` | Memory |
| `voicevox_image` | `voicevox/voicevox_engine:cpu-ubuntu20.04-latest` | Voicevox image |
| `voicevox_cpu` | `2.0` | CPU cores |
| `voicevox_memory` | `4Gi` | Memory |
| `genai_azure_openai_endpoint` | `` | Azure OpenAI endpoint URL |
| `genai_azure_openai_deployment_name` | `gpt-4o` | Deployment name |

See [variables.tf](variables.tf) for the complete list.

## Outputs

| Name | Description |
|------|-------------|
| `inclusive_ai_labs_url` | Public URL of the inclusive-ai-labs API |
| `inclusive_ai_labs_fqdn` | FQDN of the Container App |
| `voicevox_internal_fqdn` | Internal FQDN for voicevox |

## Internal Communication

The `inclusive-ai-labs` container communicates with `voicevox` via internal DNS:

- URL: `http://app-voicevox` (port 80 is the default for internal ingress)
- This is automatically configured via the `TTS_VOICEVOX_BASE_URL` environment variable

## Cleanup

```bash
terraform destroy
```

## Notes

- **voicevox** may take 1-2 minutes to start as it loads language models
- The minimum replica count is set to 1 to avoid cold start delays
- For cost optimization in non-production environments, you can set `min_replicas` to 0
