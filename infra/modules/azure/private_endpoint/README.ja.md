---
title: Azure Private Endpoint モジュール
description: 新規または既存の Private DNS zone を使って PaaS リソースへ Private Link 接続する
---

## 概要

接続先 PaaS と独立して、一つの Private Endpoint と DNS zone group を作成します。
呼び出し側からリソース ID、対応する `subresource_names`、サービス固有の DNS 設定を
渡します。PaaS のパブリック アクセス、認証、RBAC はこのモジュールでは設定しません。

接続は自動承認設定（`is_manual_connection = false`）であり、接続先への適切な権限が
必要です。手動承認や DNS zone group なしの接続は対象外です。

## DNS の管理主体

- **新規 zone**（既定）: `private_dns_zone_name` と一つ以上の
  `virtual_network_links` を指定します。zone と link はこのモジュールが管理し、
  DNS 自動登録は無効です。既存 zone ID は指定しません。
- **既存 zone**: `create_private_dns_zone = false` と `private_dns_zone_ids` を
  指定します。`private_dns_zone_name = null`、`virtual_network_links = {}` とし、
  zone と VNet link は呼び出し側が管理します。別リソース グループの zone も利用できます。

link の map キーには `spoke` などの固定した論理名を使い、plan 時に未確定のリソース ID
やランダム名を使わないでください。リンク名と VNet ID にはリソースの出力を利用できます。

同一リソース グループ内で同じ zone を重複作成しないでください。追加 Endpoint には
既存 zone ID を渡し、zone と VNet の各 link は一か所で管理します。VNet ピアリング
だけではプライベート DNS の名前解決はできません。必要なクライアント VNet をリンク
するか、DNS 転送を別途構成してください。

## 利用例

`infra/scenarios/` 配下のシナリオで PaaS モジュールと並べて呼び出します。
既存の Storage モジュールと VNet に接続する例です。

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

Storage モジュールには別途 `public_network_access_enabled = false` を指定します。
別 PaaS にもモジュール本体を変更せず、接続先と DNS の引数を変えるだけで利用できます。
呼び出し側が Key Vault と共有 DNS zone の ID を渡す例です。

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

後者は呼び出し側で管理する `privatelink.vaultcore.azure.net` zone と VNet link が必要です。
Key Vault 用 zone を新規作成する場合は、前者の新規作成方式でこの zone 名と
`subresource_names = ["vault"]` を指定します。サービスによって複数の Endpoint や zone
が必要なため、対応する subresource と zone を確認してください。

## 入力

| 名前 | 型 | 既定値 | 説明 |
|---|---|---|---|
| `name` | `string` | 必須 | `pe-*`、`psc-*`、`pdz-*` の基底名 |
| `resource_group_name` | `string` | 必須 | 作成リソースのリソース グループ |
| `location` | `string` | 必須 | Endpoint のリージョン |
| `tags` | `map(string)` | `{}` | 作成リソースのタグ |
| `subnet_id` | `string` | 必須 | Endpoint のサブネット ID |
| `private_connection_resource_id` | `string` | 必須 | 接続先 PaaS のリソース ID |
| `subresource_names` | `list(string)` | 必須 | サービスが対応する空でない Private Link subresource 一覧 |
| `create_private_dns_zone` | `bool` | `true` | 既存 ID を使わず zone と link を作成する |
| `private_dns_zone_name` | `string` | `null` | 新規作成時のみ必須 |
| `virtual_network_links` | `map(object({ name = string, virtual_network_id = string }))` | `{}` | 新規作成時のみ必須。固定キーと一意なリンク名 |
| `private_dns_zone_ids` | `list(string)` | `[]` | 既存 zone 利用時のみ必須 |

## 出力

| 名前 | 説明 |
|---|---|
| `id` | Private Endpoint ID |
| `private_ip_address` | サービス接続のプライベート IP |
| `private_dns_zone_ids` | Endpoint に関連付ける新規または既存 zone ID 一覧 |

## 検証

リポジトリ ルートから実行します。

```bash
terraform -chdir=infra/modules/azure/private_endpoint init -backend=false
terraform -chdir=infra/modules/azure/private_endpoint validate
terraform -chdir=infra/modules/azure/private_endpoint test
```

テストは Azure リソースを mock し、実環境にデプロイしません。
テストは実行時の最小 Terraform バージョンより新しい `override_during = plan` を
使用するため、現行の Terraform CLI を使用してください。CI はバージョンを固定しています。

## 参考資料

- [Azure Private Endpoint DNS configuration](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)
- [Azure Private Link availability](https://learn.microsoft.com/azure/private-link/availability)
