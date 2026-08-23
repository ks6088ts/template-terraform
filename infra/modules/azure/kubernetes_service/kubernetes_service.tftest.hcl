mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_kubernetes_cluster" {
    defaults = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test"
      name                = "aks-test"
      fqdn                = "aks-test.example.invalid"
      kube_config_raw     = "mock-kubeconfig"
      node_resource_group = "MC_rg-test_aks-test_japaneast"
      identity = {
        principal_id = "00000000-0000-0000-0000-000000000001"
        tenant_id    = "00000000-0000-0000-0000-000000000002"
        type         = "SystemAssigned"
        identity_ids = []
      }
      kubelet_identity = {
        client_id                 = "00000000-0000-0000-0000-000000000003"
        object_id                 = "00000000-0000-0000-0000-000000000004"
        user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MC_rg-test_aks-test_japaneast/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aks-test-agentpool"
      }
      kube_config = [{
        host                   = "https://aks-test.example.invalid"
        client_certificate     = "mock-client-certificate"
        client_key             = "mock-client-key"
        cluster_ca_certificate = "mock-cluster-ca-certificate"
        password               = ""
        username               = ""
      }]
    }
  }
}

run "workshop_ready_defaults" {
  command = plan

  variables {
    name                               = "test"
    resource_group_name                = "rg-test"
    location                           = "japaneast"
    user_node_pool_enabled             = true
    key_vault_secrets_provider_enabled = true
  }

  assert {
    condition = alltrue([
      azurerm_kubernetes_cluster.this.default_node_pool[0].node_count == 2,
      azurerm_kubernetes_cluster.this.default_node_pool[0].vm_size == "Standard_D4s_v3",
      azurerm_kubernetes_cluster.this.default_node_pool[0].only_critical_addons_enabled,
      azurerm_kubernetes_cluster.this.oidc_issuer_enabled,
      azurerm_kubernetes_cluster.this.workload_identity_enabled,
      azurerm_kubernetes_cluster.this.role_based_access_control_enabled,
      length(azurerm_kubernetes_cluster.this.key_vault_secrets_provider) == 1,
      azurerm_kubernetes_cluster.this.key_vault_secrets_provider[0].secret_rotation_enabled,
    ])
    error_message = "The default system pool and identity settings must remain workshop-ready."
  }

  assert {
    condition = alltrue([
      azurerm_kubernetes_cluster.this.network_profile[0].network_plugin == "azure",
      azurerm_kubernetes_cluster.this.network_profile[0].network_plugin_mode == "overlay",
      azurerm_kubernetes_cluster.this.network_profile[0].network_data_plane == "cilium",
      azurerm_kubernetes_cluster.this.network_profile[0].network_policy == "cilium",
      azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku == "standard",
    ])
    error_message = "The default network must use Azure CNI Overlay with Cilium and Standard Load Balancer."
  }

  assert {
    condition = alltrue([
      length(azurerm_kubernetes_cluster_node_pool.user) == 1,
      azurerm_kubernetes_cluster_node_pool.user[0].mode == "User",
      azurerm_kubernetes_cluster_node_pool.user[0].vm_size == "Standard_D4s_v3",
      azurerm_kubernetes_cluster_node_pool.user[0].auto_scaling_enabled,
      azurerm_kubernetes_cluster_node_pool.user[0].min_count == 1,
      azurerm_kubernetes_cluster_node_pool.user[0].max_count == 3,
    ])
    error_message = "The optional workload pool must use the expected auto-scaling defaults."
  }
}

run "workload_identity_requires_oidc" {
  command = plan

  variables {
    name                      = "test"
    resource_group_name       = "rg-test"
    location                  = "japaneast"
    oidc_issuer_enabled       = false
    workload_identity_enabled = true
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}

run "b_series_is_rejected_for_system_pool" {
  command = plan

  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "japaneast"
    vm_size             = "Standard_B2s"
  }

  expect_failures = [var.vm_size]
}

run "invalid_user_autoscaler_bounds_are_rejected" {
  command = plan

  variables {
    name                     = "test"
    resource_group_name      = "rg-test"
    location                 = "japaneast"
    user_node_pool_enabled   = true
    user_node_pool_min_count = 4
    user_node_pool_max_count = 3
  }

  expect_failures = [azurerm_kubernetes_cluster_node_pool.user]
}

run "kubenet_rejects_overlay_settings" {
  command = plan

  variables {
    name                = "test"
    resource_group_name = "rg-test"
    location            = "japaneast"
    network_plugin      = "kubenet"
    network_policy      = null
  }

  expect_failures = [azurerm_kubernetes_cluster.this]
}
