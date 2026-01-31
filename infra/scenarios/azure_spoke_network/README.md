# Azure Spoke Network

This scenario deploys a spoke network configuration for Azure hub-spoke architecture.

## Architecture

This configuration creates:

- **Virtual Network (VNet)**: A spoke VNet with configurable address space
- **Subnets**:
  - `AzureBastionSubnet`: For Azure Bastion (/26 or larger)
  - `snet-paas-*`: For PaaS Private Endpoints
  - `snet-vm-*`: For Virtual Machines
- **Storage Account**: With private endpoint for blob storage
- **Virtual Machine**: Ubuntu 24.04 LTS with SSH key authentication
- **Azure Bastion**: For secure VM access without public IPs

## Network Diagram

```text
┌─────────────────────────────────────────────────────────────┐
│                    Spoke VNet (10.1.0.0/16)                 │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │ AzureBastionSubnet │  │  PaaS Subnet    │  │  VM Subnet  │  │
│  │   10.1.0.0/26   │  │  10.1.1.0/24    │  │ 10.1.2.0/24 │  │
│  │                 │  │                 │  │             │  │
│  │  ┌───────────┐  │  │ ┌─────────────┐ │  │ ┌─────────┐ │  │
│  │  │  Bastion  │  │  │ │   Private   │ │  │ │   VM    │ │  │
│  │  │   Host    │  │  │ │  Endpoint   │ │  │ │ (Ubuntu)│ │  │
│  │  └───────────┘  │  │ │   (Blob)    │ │  │ └─────────┘ │  │
│  │                 │  │ └─────────────┘ │  │             │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
│                              │                              │
│                              ▼                              │
│                    ┌─────────────────┐                      │
│                    │ Storage Account │                      │
│                    │ (Private Only)  │                      │
│                    └─────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Azure subscription
- Terraform >= 1.6.0
- Azure CLI authenticated

## Usage

### Initialize Terraform

```bash
terraform init
```

### Plan

```bash
terraform plan
```

### Apply

```bash
terraform apply
```

### Get SSH Private Key

```bash
terraform output -raw vm_ssh_private_key > vm_key.pem
chmod 600 vm_key.pem
```

### Connect to VM via Bastion

Use Azure Portal to connect to the VM via Bastion, or use Azure CLI:

```bash
az network bastion ssh \
  --name <bastion-name> \
  --resource-group <resource-group> \
  --target-resource-id <vm-id> \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key vm_key.pem
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `name` | Base name for resources | `azurespokenetwork` |
| `location` | Azure region | `japaneast` |
| `tags` | Tags to apply | See variables.tf |
| `vnet_address_space` | VNet address space | `["10.1.0.0/16"]` |
| `subnet_bastion_address_prefixes` | Bastion subnet CIDR | `["10.1.0.0/26"]` |
| `subnet_paas_address_prefixes` | PaaS subnet CIDR | `["10.1.1.0/24"]` |
| `subnet_vm_address_prefixes` | VM subnet CIDR | `["10.1.2.0/24"]` |
| `storage_account_tier` | Storage tier | `Standard` |
| `storage_account_replication_type` | Replication type | `LRS` |
| `vm_size` | VM size | `Standard_B2s` |
| `vm_admin_username` | VM admin user | `azureuser` |
| `vm_os_disk_size_gb` | OS disk size | `30` |
| `vm_os_disk_type` | OS disk type | `Standard_LRS` |
| `bastion_sku` | Bastion SKU | `Basic` |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | Resource group name |
| `vnet_id` | Spoke VNet ID |
| `vnet_name` | Spoke VNet name |
| `storage_account_name` | Storage account name |
| `private_endpoint_blob_ip` | Private endpoint IP for blob |
| `vm_name` | VM name |
| `vm_private_ip` | VM private IP |
| `vm_ssh_private_key` | SSH private key (sensitive) |
| `bastion_name` | Bastion host name |
| `bastion_public_ip` | Bastion public IP |

## Extending for Hub-Spoke

To connect this spoke to a hub VNet, add VNet peering:

```hcl
variable "hub_vnet_id" {
  description = "ID of the hub VNet for peering"
  type        = string
  default     = ""
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                     = var.hub_vnet_id != "" ? 1 : 0
  name                      = "peer-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = var.hub_vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}
```

## References

- [Hub-spoke network topology in Azure](https://learn.microsoft.com/azure/architecture/networking/architecture/hub-spoke)
- [Azure Bastion documentation](https://learn.microsoft.com/azure/bastion/)
- [Private endpoints for Azure Storage](https://learn.microsoft.com/azure/storage/common/storage-private-endpoints)
