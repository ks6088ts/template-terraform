---
description: Azure Database for PostgreSQL Flexible Server をデプロイするシナリオ
---

# azure_postgresql

Azure Database for PostgreSQL Flexible Server をデプロイするシナリオです。

## 使用方法

共通の [Azure 認証](../../../docs/tips/provider-authentication.ja.md)、
[Terraform ワークフロー](../../../docs/tips/terraform-workflow.ja.md)、および必要に応じて
[Azure Blob Storage バックエンド](../../../docs/tips/azure-blob-backend.ja.md)を設定してください。
このシナリオの Makefile コマンドでは `SCENARIO=azure_postgresql` を指定します。

既存のローカル `backend.tf` を利用していた場合は、共通ガイドへの移行について
[PostgreSQL シナリオのアップグレード手順](../../../docs/tips/azure-blob-backend.ja.md#postgresql-シナリオのアップグレード)
を確認してください。

管理者パスワードは自動生成されます。接続情報は出力から取得します。

```bash
# 接続 URI（パスワードを含む）
terraform output -raw postgresql_connection_uri

# 個別に取得する場合
terraform output -raw postgresql_administrator_password
terraform output postgresql_server_fqdn
```

パスワードやデータベース名などを指定する場合は、変数を渡します。

```bash
terraform apply -auto-approve \
  -var='administrator_password=YourSecurePassword123!' \
  -var='database_name=mydb'
```

## 変数

| 変数                     | 既定値            | 説明                                 |
|--------------------------|-------------------|--------------------------------------|
| `name`                   | `azurepostgresql` | リソースのベース名                   |
| `location`               | `japaneast`       | リージョン                           |
| `administrator_login`    | `psqladmin`       | 管理者ログイン                       |
| `administrator_password` | 自動生成          | 指定した場合は任意のパスワードを使用 |
| `database_name`          | `appdb`           | 作成するデータベース名               |
| `postgresql_version`     | `17`              | PostgreSQL バージョン                |
| `sku_name`               | `B_Standard_B1ms` | SKU                                  |

## 出力

| 出力                                | 説明                            |
|-------------------------------------|---------------------------------|
| `resource_group_name`               | リソースグループ名              |
| `postgresql_connection_uri`         | 接続 URI（`sensitive`）         |
| `postgresql_administrator_login`    | 管理者ログイン                  |
| `postgresql_administrator_password` | 管理者パスワード（`sensitive`） |
| `postgresql_server_fqdn`            | サーバー FQDN                   |
| `postgresql_database_name`          | データベース名                  |
