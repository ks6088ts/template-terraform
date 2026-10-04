---
title: Azure Storage モジュール
description: オプションのデータサービスを備えた Azure Storage Account を作成する
---

## 概要

このモジュールは Azure Storage Account を作成し、必要に応じてキュー、コンテナー、
論理削除、マネージド ID を追加します。既定値では、
階層型名前空間、パブリック ネットワーク アクセス、システム割り当てマネージド ID は
有効です。プライベート接続は別途構成します。

## プライベート ネットワーク

独立した [Private Endpoint モジュール](../private_endpoint/README.ja.md)を Storage と
並べて呼び出します。Storage はアカウントとネットワーク アクセス設定を、接続モジュールは
Endpoint と DNS 設定を管理します。プライベート接続のみに制限する場合は
`public_network_access_enabled = false` を設定します。

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

接続情報は接続モジュールの `id`、`private_ip_address`、`private_dns_zone_ids` を
参照してください。DNS を共有する場合は接続モジュールの既存 zone 方式を使います。

## 入力

| 名前 | 型 | 既定値 | 説明 |
| --- | --- | --- | --- |
| `name` | `string` | 必須 | 関連リソースに使用する基本名 |
| `storage_account_name` | `string` | 必須 | グローバルで一意な Storage Account 名 |
| `resource_group_name` | `string` | 必須 | リソース グループ名 |
| `location` | `string` | 必須 | Azure リージョン |
| `tags` | `map(string)` | `{}` | リソースに適用するタグ |
| `account_tier` | `string` | `Standard` | Storage Account の層 |
| `account_replication_type` | `string` | `LRS` | ストレージのレプリケーション方式 |
| `enable_hns` | `bool` | `true` | 階層型名前空間を有効化するかどうか |
| `public_network_access_enabled` | `bool` | `true` | パブリック ネットワーク アクセスを有効化するか |
| `allow_nested_items_to_be_public` | `bool` | `false` | 入れ子項目のパブリック化を許可するかどうか |
| `https_traffic_only_enabled` | `bool` | `true` | HTTPS 通信のみを許可するかどうか |
| `min_tls_version` | `string` | `TLS1_2` | TLS の最小バージョン |
| `shared_access_key_enabled` | `bool` | `true` | 共有キー認証を有効化するかどうか |
| `enable_identity` | `bool` | `true` | システム割り当てマネージド ID を有効化するか |
| `enable_blob_soft_delete` | `bool` | `false` | Blob とコンテナーの論理削除を有効化するか |
| `blob_soft_delete_retention_days` | `number` | `7` | 削除した Blob の保持日数 |
| `container_soft_delete_retention_days` | `number` | `7` | 削除したコンテナーの保持日数 |
| `create_queue` | `bool` | `false` | ストレージ キューを 1 つ作成するかどうか |
| `queue_data_contributor_principal_id` | `string` | `null` | Queue データ アクセスを付与するプリンシパル |
| `create_container` | `bool` | `false` | Blob コンテナーを 1 つ作成するかどうか |
| `container_name` | `string` | `default` | Blob コンテナー名 |
| `container_access_type` | `string` | `private` | Blob コンテナーのアクセス種別 |

## 出力

| 名前 | 説明 |
| --- | --- |
| `account_id` | Storage Account ID |
| `account_name` | Storage Account 名 |
| `hns_enabled` | 階層型名前空間が有効かどうか |
| `primary_access_key` | プライマリ アクセス キー。共有キー認証が無効な場合は `null` |
| `primary_blob_endpoint` | プライマリ Blob エンドポイント |
| `primary_dfs_endpoint` | プライマリ Data Lake Storage エンドポイント |
| `primary_queue_endpoint` | プライマリ Queue エンドポイント |
| `queue_name` | キュー名。無効な場合は `null` |
| `queue_id` | キュー ID。無効な場合は `null` |
| `queue_data_contributor_role_assignment_id` | Queue データ ロール割り当て ID。無効な場合は `null` |
| `container_name` | コンテナー名。無効な場合は `null` |
| `container_id` | コンテナー ID。無効な場合は `null` |
