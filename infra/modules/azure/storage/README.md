---
title: Azure Storage module
description: Creates an Azure Storage account with optional data services
---

## Overview

This module creates an Azure Storage account with optional queue, container,
soft-delete, and managed identity resources. By default,
hierarchical namespace, public network access, and a system-assigned managed
identity are enabled. Private connectivity is configured separately.

## Private networking

Call the separate [Private Endpoint module](../private_endpoint/README.md)
alongside Storage. Storage owns the account and its network access policy;
the connection module owns the endpoint and DNS configuration. Set
`public_network_access_enabled = false` for a private-only account.

```hcl
module "storage" {
  source = "../../modules/azure/storage"

  name                          = "example"
  storage_account_name          = "stexample12345678"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  public_network_access_enabled = false

}

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

Read `id`, `private_ip_address`, and `private_dns_zone_ids` from the connection
module.
For shared DNS, use the connection module's existing-zone mode.

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
| `enable_hns`                           | `bool`        | `true`     | Enables hierarchical namespace                   |
| `public_network_access_enabled`        | `bool`        | `true`     | Enables public network access                    |
| `allow_nested_items_to_be_public`      | `bool`        | `false`    | Allows nested items to become public             |
| `https_traffic_only_enabled`           | `bool`        | `true`     | Requires HTTPS traffic                           |
| `min_tls_version`                      | `string`      | `TLS1_2`   | Minimum TLS version                              |
| `shared_access_key_enabled`            | `bool`        | `true`     | Enables shared key authorization                 |
| `enable_identity`                      | `bool`        | `true`     | Enables a system-assigned managed identity       |
| `enable_blob_soft_delete`              | `bool`        | `false`    | Enables blob and container soft delete           |
| `blob_soft_delete_retention_days`      | `number`      | `7`        | Deleted blob retention period in days            |
| `container_soft_delete_retention_days` | `number`      | `7`        | Deleted container retention period in days       |
| `create_queue`                         | `bool`        | `false`    | Creates one storage queue                        |
| `queue_data_contributor_principal_id`  | `string`      | `null`     | Principal granted Queue data access              |
| `create_container`                     | `bool`        | `false`    | Creates one Blob container                       |
| `container_name`                       | `string`      | `default`  | Blob container name                              |
| `container_access_type`                | `string`      | `private`  | Blob container access type                       |

## Outputs

| Name                                           | Description                                                             |
|------------------------------------------------|-------------------------------------------------------------------------|
| `account_id`                                   | Storage Account ID                                                      |
| `account_name`                                 | Storage Account name                                                    |
| `hns_enabled`                                  | Whether hierarchical namespace is enabled                              |
| `primary_access_key`                           | Primary access key, or `null` when shared-key authentication is disabled |
| `primary_blob_endpoint`                        | Primary Blob endpoint                                                   |
| `primary_dfs_endpoint`                         | Primary Data Lake Storage endpoint                                      |
| `primary_queue_endpoint`                       | Primary Queue endpoint                                                  |
| `queue_name`                                   | Queue name, or `null` when disabled                                     |
| `queue_id`                                     | Queue ID, or `null` when disabled                                       |
| `queue_data_contributor_role_assignment_id`    | Queue data role assignment ID, or `null`                                |
| `container_name`                               | Container name, or `null` when disabled                                 |
| `container_id`                                 | Container ID, or `null` when disabled                                   |