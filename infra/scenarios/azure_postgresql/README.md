---
description: Scenario for deploying Azure Database for PostgreSQL Flexible Server
---

# azure_postgresql

This scenario deploys Azure Database for PostgreSQL Flexible Server.

## Usage

Configure the shared [Azure authentication](../../../docs/tips/provider-authentication.md),
[Terraform workflow](../../../docs/tips/terraform-workflow.md), and, when needed,
[Azure Blob Storage backend](../../../docs/tips/azure-blob-backend.md).
Specify `SCENARIO=azure_postgresql` when running Makefile commands for this scenario.

If you previously used a local `backend.tf`, see the
[PostgreSQL scenario upgrade instructions](../../../docs/tips/azure-blob-backend.md#upgrade-the-postgresql-scenario)
to migrate to the shared guidance.

The administrator password is generated automatically. Retrieve the connection information from the outputs.

```bash
# Connection URI, including the password
terraform output -raw postgresql_connection_uri

# Retrieve individual values
terraform output -raw postgresql_administrator_password
terraform output postgresql_server_fqdn
```

Pass variables to specify values such as the password or database name.

```bash
terraform apply -auto-approve \
  -var='administrator_password=YourSecurePassword123!' \
  -var='database_name=mydb'
```

## Variables

| Variable                 | Default           | Description                               |
|--------------------------|-------------------|-------------------------------------------|
| `name`                   | `azurepostgresql` | Base name for resources                   |
| `location`               | `japaneast`       | Region                                    |
| `administrator_login`    | `psqladmin`       | Administrator login                       |
| `administrator_password` | Generated         | Uses the specified password when provided |
| `database_name`          | `appdb`           | Name of the database to create            |
| `postgresql_version`     | `17`              | PostgreSQL version                        |
| `sku_name`               | `B_Standard_B1ms` | SKU                                       |

## Outputs

| Output                              | Description                          |
|-------------------------------------|--------------------------------------|
| `resource_group_name`               | Resource group name                  |
| `postgresql_connection_uri`         | Connection URI (`sensitive`)         |
| `postgresql_administrator_login`    | Administrator login                  |
| `postgresql_administrator_password` | Administrator password (`sensitive`) |
| `postgresql_server_fqdn`            | Server FQDN                          |
| `postgresql_database_name`          | Database name                        |
