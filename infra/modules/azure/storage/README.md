---
title: Azure Storage module
description: Creates an Azure Storage account with optional data services and private Blob connectivity
---

## Overview

This module creates an Azure Storage account with optional queue, container,
soft-delete, managed identity, and Blob private endpoint resources. By default,
it preserves the public storage behavior used by existing scenarios: public
network access and a system-assigned managed identity are enabled, while the
private endpoint is disabled.

## Private networking

Set `private_endpoint` to create a Blob private endpoint. Its fields have the
following behavior:

* `subnet_id` identifies the subnet that hosts the private endpoint
* `create_private_dns_zone` defaults to `true` and controls whether the module
  owns the Blob private DNS zone and virtual network link
* `virtual_network_id` is required when `create_private_dns_zone` is `true`
* `private_dns_zone_id` is required when `create_private_dns_zone` is `false`;
  the caller then owns the zone and its virtual network links

The module creates `privatelink.blob.core.windows.net` and links it to the
specified virtual network when `create_private_dns_zone` is `true`. Set
`public_network_access_enabled = false` separately when the storage account
must be private-only.

> [!IMPORTANT]
> A resource group can contain only one private DNS zone with the name
> `privatelink.blob.core.windows.net`. For additional storage module instances
> in the same resource group, pass the existing zone ID and manage its virtual
> network links outside this module.

```hcl
module "storage" {
  source = "../../modules/azure/storage"

  name                          = "example"
  storage_account_name          = "stexample12345678"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  public_network_access_enabled = false

  private_endpoint = {
    subnet_id          = module.virtual_network.subnet_ids["snet-private-endpoints"]
    virtual_network_id = module.virtual_network.vnet_id
  }
}
```

## Inputs

| Name                                   | Type          | Default    | Description                                      |
|----------------------------------------|---------------|------------|--------------------------------------------------|
| `name`                                 | `string`      | Required   | Base name used by related resources              |
| `storage_account_name`                 | `string`      | Required   | Globally unique storage account name             |
| `resource_group_name`                  | `string`      | Required   | Resource group name                              |
| `location`                             | `string`      | Required   | Azure region                                     |
| `tags`                                 | `map(string)` | `{}`       | Tags applied to resources                        |
| `account_tier`                         | `string`      | `Standard` | Storage account tier                             |
| `account_replication_type`             | `string`      | `LRS`      | Storage replication type                         |
| `is_hns_enabled`                       | `bool`        | `false`    | Enables hierarchical namespace                   |
| `public_network_access_enabled`        | `bool`        | `true`     | Enables public network access                    |
| `allow_nested_items_to_be_public`      | `bool`        | `false`    | Allows nested items to become public             |
| `https_traffic_only_enabled`           | `bool`        | `true`     | Requires HTTPS traffic                           |
| `min_tls_version`                      | `string`      | `TLS1_2`   | Minimum TLS version                              |
| `shared_access_key_enabled`            | `bool`        | `true`     | Enables shared key authorization                 |
| `enable_identity`                      | `bool`        | `true`     | Enables a system-assigned managed identity       |
| `private_endpoint`                     | `object`      | `null`     | Optional Blob private endpoint configuration     |
| `enable_blob_soft_delete`              | `bool`        | `false`    | Enables blob and container soft delete           |
| `blob_soft_delete_retention_days`      | `number`      | `7`        | Deleted blob retention period in days            |
| `container_soft_delete_retention_days` | `number`      | `7`        | Deleted container retention period in days       |
| `create_queue`                         | `bool`        | `false`    | Creates one storage queue                        |
| `create_container`                     | `bool`        | `false`    | Creates one Blob container                       |
| `container_name`                       | `string`      | `default`  | Blob container name                              |
| `container_access_type`                | `string`      | `private`  | Blob container access type                       |

## Outputs

| Name                    | Description                                      |
|-------------------------|--------------------------------------------------|
| `account_id`            | Storage account ID                               |
| `account_name`          | Storage account name                             |
| `primary_access_key`    | Primary storage access key                       |
| `primary_blob_endpoint` | Primary Blob endpoint                            |
| `primary_dfs_endpoint`  | Primary Data Lake Storage endpoint               |
| `queue_name`            | Queue name, or `null` when disabled               |
| `container_name`        | Container name, or `null` when disabled           |
| `container_id`          | Container ID, or `null` when disabled             |
| `private_endpoint_id`   | Blob private endpoint ID, or `null` when disabled |
| `private_endpoint_ip`   | Blob private IP, or `null` when disabled          |
| `private_dns_zone_id`   | Blob private DNS zone ID, or `null` when disabled |