---
title: Azure Storage モジュール
description: オプションのデータサービスと Blob プライベート接続を備えた Azure Storage Account を作成する
---

## 概要

このモジュールは Azure Storage Account を作成し、必要に応じてキュー、コンテナー、
論理削除、マネージド ID、Blob プライベート エンドポイントを追加します。既定値では、
既存シナリオが利用するパブリック構成との互換性を維持します。パブリック ネットワーク
アクセスとシステム割り当てマネージド ID は有効で、プライベート エンドポイントは無効です。

## プライベート ネットワーク

`private_endpoint` を設定すると、Blob プライベート エンドポイントを作成します。
各フィールドの動作は次のとおりです。

* `subnet_id` はプライベート エンドポイントを配置するサブネットを指定します
* `create_private_dns_zone` の既定値は `true` です。Blob プライベート DNS ゾーンと
  仮想ネットワーク リンクをこのモジュールで管理するかどうかを指定します
* `virtual_network_id` は `create_private_dns_zone` が `true` の場合に必須です
* `private_dns_zone_id` は `create_private_dns_zone` が `false` の場合に必須です。この場合、
  呼び出し側が DNS ゾーンと仮想ネットワーク リンクを管理します

`create_private_dns_zone` が `true` の場合、モジュールは
`privatelink.blob.core.windows.net` を作成し、指定された仮想ネットワークへリンクします。
Storage Account をプライベート接続のみに制限する場合は、別途
`public_network_access_enabled = false` を設定します。

> [!IMPORTANT]
> 1 つのリソース グループには、`privatelink.blob.core.windows.net` という名前の
> プライベート DNS ゾーンを 1 つだけ作成できます。同じリソース グループでこのモジュールを
> 複数回使用する場合は、既存ゾーンの ID を渡し、仮想ネットワーク リンクをモジュール外で管理します。

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

## 入力

| 名前                                   | 型            | 既定値     | 説明                                           |
|----------------------------------------|---------------|------------|------------------------------------------------|
| `name`                                 | `string`      | 必須       | 関連リソースに使用する基本名                   |
| `storage_account_name`                 | `string`      | 必須       | グローバルで一意な Storage Account 名          |
| `resource_group_name`                  | `string`      | 必須       | リソース グループ名                            |
| `location`                             | `string`      | 必須       | Azure リージョン                               |
| `tags`                                 | `map(string)` | `{}`       | リソースに適用するタグ                         |
| `account_tier`                         | `string`      | `Standard` | Storage Account の層                           |
| `account_replication_type`             | `string`      | `LRS`      | ストレージのレプリケーション方式               |
| `is_hns_enabled`                       | `bool`        | `false`    | 階層型名前空間を有効化するかどうか             |
| `public_network_access_enabled`        | `bool`        | `true`     | パブリック ネットワーク アクセスを有効化するか |
| `allow_nested_items_to_be_public`      | `bool`        | `false`    | 入れ子項目のパブリック化を許可するかどうか     |
| `https_traffic_only_enabled`           | `bool`        | `true`     | HTTPS 通信のみを許可するかどうか               |
| `min_tls_version`                      | `string`      | `TLS1_2`   | TLS の最小バージョン                           |
| `shared_access_key_enabled`            | `bool`        | `true`     | 共有キー認証を有効化するかどうか               |
| `enable_identity`                      | `bool`        | `true`     | システム割り当てマネージド ID を有効化するか   |
| `private_endpoint`                     | `object`      | `null`     | Blob プライベート エンドポイントの設定         |
| `enable_blob_soft_delete`              | `bool`        | `false`    | Blob とコンテナーの論理削除を有効化するか      |
| `blob_soft_delete_retention_days`      | `number`      | `7`        | 削除した Blob の保持日数                       |
| `container_soft_delete_retention_days` | `number`      | `7`        | 削除したコンテナーの保持日数                   |
| `create_queue`                         | `bool`        | `false`    | ストレージ キューを 1 つ作成するかどうか       |
| `create_container`                     | `bool`        | `false`    | Blob コンテナーを 1 つ作成するかどうか         |
| `container_name`                       | `string`      | `default`  | Blob コンテナー名                              |
| `container_access_type`                | `string`      | `private`  | Blob コンテナーのアクセス種別                  |

## 出力

| 名前                    | 説明                                                   |
|-------------------------|--------------------------------------------------------|
| `account_id`            | Storage Account ID                                     |
| `account_name`          | Storage Account 名                                     |
| `primary_access_key`    | プライマリ ストレージ アクセス キー                    |
| `primary_blob_endpoint` | プライマリ Blob エンドポイント                        |
| `primary_dfs_endpoint`  | プライマリ Data Lake Storage エンドポイント           |
| `queue_name`            | キュー名。無効な場合は `null`                          |
| `container_name`        | コンテナー名。無効な場合は `null`                      |
| `container_id`          | コンテナー ID。無効な場合は `null`                     |
| `private_endpoint_id`   | Blob プライベート エンドポイント ID。無効な場合は `null` |
| `private_endpoint_ip`   | Blob プライベート IP。無効な場合は `null`              |
| `private_dns_zone_id`   | Blob プライベート DNS ゾーン ID。無効な場合は `null`   |