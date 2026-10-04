---
title: Azure Private Endpoint module
description: Connects a PaaS resource through Private Link with a new or existing Private DNS zone
---

## Overview

This module creates one Private Endpoint and its DNS zone group independently
of the target PaaS resource. The caller supplies the resource ID, supported
`subresource_names`, and service-specific DNS configuration. It does not
configure the PaaS resource's public access, authentication, or RBAC.

Connections use automatic approval (`is_manual_connection = false`), requiring
appropriate permissions on the target resource. Manual approval and endpoints
without a DNS zone group are not supported.

## DNS ownership

- **New zone** (default): supply `private_dns_zone_name` and one or more
  `virtual_network_links`. The module owns the zone and links, with DNS
  registration disabled. Do not pass existing zone IDs.
- **Existing zones**: set `create_private_dns_zone = false` and supply
  `private_dns_zone_ids`. Leave `private_dns_zone_name = null` and
  `virtual_network_links = {}`. The caller owns the zones and VNet links;
  zones in another resource group are supported.

Use stable logical keys such as `spoke` for the link map, not resource IDs or
random names that are unknown during planning. Link names and VNet IDs may
depend on resource outputs.

Do not create the same zone repeatedly in one resource group. Share zone IDs
across additional endpoints and manage each zone/VNet link once. VNet peering
alone does not provide private DNS resolution; link every client VNet that
needs it or configure DNS forwarding separately.

## Usage

From a scenario under `infra/scenarios/`, compose this module alongside the
PaaS module. For an existing Storage module and VNet:

```hcl
module "private_endpoint_blob" {
  source = "../../modules/azure/private_endpoint"

  name                           = "blob-example"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  private_connection_resource_id = module.storage.account_id
  subnet_id                      = module.virtual_network.subnet_ids["snet-private-endpoints"]
  subresource_names              = ["blob"]
  private_dns_zone_name           = "privatelink.blob.core.windows.net"
  virtual_network_links = {
    spoke = {
      name               = "link-blob-example"
      virtual_network_id = module.virtual_network.vnet_id
    }
  }
}
```

Set `public_network_access_enabled = false` on the Storage module separately.
For another PaaS, change the target and DNS parameters, not the module code.
For example, with caller-supplied Key Vault and shared DNS zone IDs:

```hcl
module "private_endpoint_vault" {
  source = "../../modules/azure/private_endpoint"

  name                           = "vault-example"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  private_connection_resource_id = var.key_vault_id
  subnet_id                      = module.virtual_network.subnet_ids["snet-private-endpoints"]
  subresource_names              = ["vault"]
  create_private_dns_zone        = false
  private_dns_zone_ids           = [var.key_vault_private_dns_zone_id]
}
```

The second example requires a caller-managed `privatelink.vaultcore.azure.net`
zone and its VNet links. For a new Key Vault zone, use the first example's
new-zone mode with that zone name and `subresource_names = ["vault"]`.
Check the target service's supported subresources and zones; some services
require multiple endpoints or zones.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | Required | Base name; produces `pe-*`, `psc-*`, and `pdz-*` names |
| `resource_group_name` | `string` | Required | Resource group for created resources |
| `location` | `string` | Required | Endpoint region |
| `tags` | `map(string)` | `{}` | Tags for created resources |
| `subnet_id` | `string` | Required | Endpoint subnet ID |
| `private_connection_resource_id` | `string` | Required | Target PaaS resource ID |
| `subresource_names` | `list(string)` | Required | Non-empty, service-supported Private Link subresources |
| `create_private_dns_zone` | `bool` | `true` | Create a zone and links instead of using existing IDs |
| `private_dns_zone_name` | `string` | `null` | Required only for a new zone |
| `virtual_network_links` | `map(object({ name = string, virtual_network_id = string }))` | `{}` | Required only for a new zone; stable keys and unique link names |
| `private_dns_zone_ids` | `list(string)` | `[]` | Required only for existing zones |

## Outputs

| Name | Description |
|---|---|
| `id` | Private Endpoint ID |
| `private_ip_address` | Service connection's private IP address |
| `private_dns_zone_ids` | Created or existing zone IDs associated with the endpoint |

## Validation

From the repository root:

```bash
terraform -chdir=infra/modules/azure/private_endpoint init -backend=false
terraform -chdir=infra/modules/azure/private_endpoint validate
terraform -chdir=infra/modules/azure/private_endpoint test
```

Tests use mocked Azure resources; they do not deploy infrastructure.
Use a current Terraform CLI for tests (CI pins its version); the tests use
`override_during = plan`, which is newer than the module's runtime minimum.

## References

- [Azure Private Endpoint DNS configuration](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)
- [Azure Private Link availability](https://learn.microsoft.com/azure/private-link/availability)
