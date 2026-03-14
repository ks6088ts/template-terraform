# Tutorials

## How to set backend configuration

Put the following code in `infra/scenarios/YOUR_SCENARIO/backend.tf` and replace the values with your own.

```hcl
terraform {
  backend "azurerm" {
    use_cli              = true
    use_azuread_auth     = true
    resource_group_name  = "YOUR_RESOURCE_GROUP_NAME"
    storage_account_name = "YOUR_STORAGE_ACCOUNT_NAME"
    container_name       = "YOUR_CONTAINER_NAME"
    key                  = "YOUR_SCENARIO.dev.tfstate"
  }
}
```

## How to use scenarios

### with GNU Make

```shell
# Help
make

# set scenario
SCENARIO=hello_world

# set variables
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# deploy resources
make deploy SCENARIO=$SCENARIO

# destroy resources
make destroy SCENARIO=$SCENARIO
```

## References

- [🌟 Microsoft MCP Servers](https://github.com/microsoft/mcp)
- [Terraform MCP Server](https://github.com/hashicorp/terraform-mcp-server)
- [Authenticating using the Azure CLI](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/guides/azure_cli)
