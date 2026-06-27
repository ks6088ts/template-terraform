# azure_postgresql

Azure Database for PostgreSQL Flexible Server をデプロイするシナリオです。

## 使い方

```shell
az login
terraform init
terraform apply -auto-approve
```

管理者パスワードは自動生成されます。接続情報は出力から取得します。

```shell
# 接続 URI（パスワード込み）
terraform output -raw postgresql_connection_uri

# 個別に取得する場合
terraform output -raw postgresql_administrator_password
terraform output postgresql_server_fqdn
```

パスワードやデータベース名などを指定したい場合は変数を渡します。

```shell
terraform apply -auto-approve \
  -var='administrator_password=YourSecurePassword123!' \
  -var='database_name=mydb'
```

## 変数

| 変数 | 既定値 | 説明 |
|------|--------|------|
| `name` | `azurepostgresql` | リソースのベース名 |
| `location` | `japaneast` | リージョン |
| `administrator_login` | `psqladmin` | 管理者ログイン |
| `administrator_password` | （自動生成） | 指定すると任意のパスワードを使用 |
| `database_name` | `appdb` | 作成するデータベース名 |
| `postgresql_version` | `17` | PostgreSQL バージョン |
| `sku_name` | `B_Standard_B1ms` | SKU |

## 出力

| 出力 | 説明 |
|------|------|
| `postgresql_connection_uri` | 接続 URI（`sensitive`） |
| `postgresql_administrator_login` | 管理者ログイン |
| `postgresql_administrator_password` | 管理者パスワード（`sensitive`） |
| `postgresql_server_fqdn` | サーバー FQDN |
| `postgresql_database_name` | データベース名 |
