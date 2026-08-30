mock_provider "azurerm" {
  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test1234"
      fqdn                       = "aks-test1234.japaneast.azmk8s.io"
      current_kubernetes_version = "1.35.2"
      oidc_issuer_url            = "https://japaneast.oic.prod-aks.azure.com/00000000-0000-0000-0000-000000000000/00000000-0000-0000-0000-000000000001/"
      node_resource_group        = "MC_rg-test_aks-test1234_japaneast"
      node_resource_group_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MC_rg-test_aks-test1234_japaneast"
      oms_agent = {
        oms_agent_identity = {
          client_id                 = "00000000-0000-0000-0000-000000000004"
          object_id                 = "00000000-0000-0000-0000-000000000005"
          user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MC_rg-test_aks-test1234_japaneast/providers/Microsoft.ManagedIdentity/userAssignedIdentities/omsagent-aks-test1234"
        }
      }
    }
  }
}

run "default_cluster" {
  command = plan

  variables {
    name                = "test1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
  }

  assert {
    condition = alltrue([
      azurerm_kubernetes_cluster.this.name == "aks-test1234",
      azurerm_kubernetes_cluster.this.sku_tier == "Free",
      var.kubernetes_version == null,
      azurerm_kubernetes_cluster.this.oidc_issuer_enabled,
      azurerm_kubernetes_cluster.this.workload_identity_enabled,
      azurerm_kubernetes_cluster.this.role_based_access_control_enabled,
      !azurerm_kubernetes_cluster.this.local_account_disabled,
      azurerm_kubernetes_cluster.this.automatic_upgrade_channel == "stable",
      azurerm_kubernetes_cluster.this.node_os_upgrade_channel == "NodeImage",
      azurerm_kubernetes_cluster.this.image_cleaner_enabled,
      azurerm_kubernetes_cluster.this.image_cleaner_interval_hours == 168,
    ])
    error_message = "The AKS cluster must use the secure, automatically maintained learning baseline."
  }

  assert {
    condition = alltrue([
      azurerm_kubernetes_cluster.this.default_node_pool[0].name == "system",
      azurerm_kubernetes_cluster.this.default_node_pool[0].node_count == 2,
      azurerm_kubernetes_cluster.this.default_node_pool[0].vm_size == "Standard_D4s_v5",
      azurerm_kubernetes_cluster.this.default_node_pool[0].os_sku == "AzureLinux3",
      azurerm_kubernetes_cluster.this.default_node_pool[0].only_critical_addons_enabled,
      azurerm_kubernetes_cluster.this.default_node_pool[0].upgrade_settings[0].max_surge == "33%",
    ])
    error_message = "The default pool must be a dedicated two-node Azure Linux system pool."
  }

  assert {
    condition = alltrue([
      length(azurerm_kubernetes_cluster_node_pool.user) == 1,
      azurerm_kubernetes_cluster_node_pool.user["user"].mode == "User",
      azurerm_kubernetes_cluster_node_pool.user["user"].auto_scaling_enabled,
      azurerm_kubernetes_cluster_node_pool.user["user"].node_count == 1,
      azurerm_kubernetes_cluster_node_pool.user["user"].min_count == 1,
      azurerm_kubernetes_cluster_node_pool.user["user"].max_count == 3,
      azurerm_kubernetes_cluster_node_pool.user["user"].os_sku == "AzureLinux3",
      azurerm_kubernetes_cluster_node_pool.user["user"].upgrade_settings[0].max_surge == "33%",
    ])
    error_message = "The default user pool must use Azure Linux and autoscale from one to three nodes."
  }

  assert {
    condition = alltrue([
      azurerm_kubernetes_cluster.this.network_profile[0].network_plugin == "azure",
      azurerm_kubernetes_cluster.this.network_profile[0].network_plugin_mode == "overlay",
      azurerm_kubernetes_cluster.this.network_profile[0].network_data_plane == "cilium",
      azurerm_kubernetes_cluster.this.network_profile[0].network_policy == "cilium",
      azurerm_kubernetes_cluster.this.network_profile[0].pod_cidr == "10.244.0.0/16",
      azurerm_kubernetes_cluster.this.network_profile[0].service_cidr == "10.0.0.0/16",
      azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip == "10.0.0.10",
      azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku == "standard",
      azurerm_kubernetes_cluster.this.network_profile[0].outbound_type == "loadBalancer",
    ])
    error_message = "The default network must use Azure CNI Overlay powered by Cilium and managed load-balancer egress."
  }

  assert {
    condition = alltrue([
      length(azurerm_role_assignment.acr_pull) == 0,
      length(azurerm_kubernetes_cluster.this.oms_agent) == 0,
    ])
    error_message = "Optional ACR and Container Insights integration must be disabled when no resource IDs are supplied."
  }
}

run "optional_entra_and_monitoring" {
  command = plan

  variables {
    name                       = "test1234"
    resource_group_name        = "rg-test"
    location                   = "japaneast"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test1234"
    api_server_authorized_ip_ranges = [
      "203.0.113.10/32",
    ]
    entra_id = {
      tenant_id              = "00000000-0000-0000-0000-000000000006"
      admin_group_object_ids = ["00000000-0000-0000-0000-000000000007"]
      azure_rbac_enabled     = true
    }
    local_account_disabled = true
    maintenance_window_auto_upgrade = {
      day_of_week = "Sunday"
      start_time  = "03:00"
      utc_offset  = "+09:00"
    }
    maintenance_window_node_os = {
      day_of_week = "Sunday"
      start_time  = "07:00"
      utc_offset  = "+09:00"
    }
  }

  assert {
    condition = alltrue([
      azurerm_kubernetes_cluster.this.local_account_disabled,
      azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control[0].azure_rbac_enabled,
      toset(azurerm_kubernetes_cluster.this.azure_active_directory_role_based_access_control[0].admin_group_object_ids) == toset(["00000000-0000-0000-0000-000000000007"]),
      azurerm_kubernetes_cluster.this.oms_agent[0].msi_auth_for_monitoring_enabled,
      azurerm_kubernetes_cluster.this.oms_agent[0].log_analytics_workspace_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test1234",
      toset(azurerm_kubernetes_cluster.this.api_server_access_profile[0].authorized_ip_ranges) == toset(["203.0.113.10/32"]),
      azurerm_kubernetes_cluster.this.maintenance_window_auto_upgrade[0].frequency == "Weekly",
      azurerm_kubernetes_cluster.this.maintenance_window_auto_upgrade[0].start_time == "03:00",
      azurerm_kubernetes_cluster.this.maintenance_window_node_os[0].frequency == "Weekly",
      azurerm_kubernetes_cluster.this.maintenance_window_node_os[0].start_time == "07:00",
      length(azurerm_role_assignment.acr_pull) == 0,
    ])
    error_message = "Optional Microsoft Entra and managed-identity Container Insights integration must be configured without local credentials."
  }
}

run "workload_identity_requires_oidc" {
  command = plan

  variables {
    name                      = "test1234"
    resource_group_name       = "rg-test"
    location                  = "japaneast"
    oidc_issuer_enabled       = false
    workload_identity_enabled = true
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "disabled_local_accounts_require_entra" {
  command = plan

  variables {
    name                   = "test1234"
    resource_group_name    = "rg-test"
    location               = "japaneast"
    local_account_disabled = true
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "critical_system_pool_requires_user_pool" {
  command = plan

  variables {
    name                = "test1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
    user_node_pools     = {}
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "node_image_upgrade_requires_node_image_channel" {
  command = plan

  variables {
    name                      = "test1234"
    resource_group_name       = "rg-test"
    location                  = "japaneast"
    automatic_upgrade_channel = "node-image"
    node_os_upgrade_channel   = "None"
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "cilium_requires_azure_cni_overlay" {
  command = plan

  variables {
    name                = "test1234"
    resource_group_name = "rg-test"
    location            = "japaneast"
    network_profile = {
      network_plugin      = "kubenet"
      network_plugin_mode = "overlay"
      network_data_plane  = "cilium"
      network_policy      = "cilium"
    }
  }

  expect_failures = [var.network_profile]
}
