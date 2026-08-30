mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    override_during = plan

    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurekubernetesplayground-test1234"
    }
  }

  mock_resource "azurerm_container_registry" {
    override_during = plan

    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurekubernetesplayground-test1234/providers/Microsoft.ContainerRegistry/registries/acrtest1234"
      login_server = "acrtest1234.azurecr.io"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    override_during = plan

    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurekubernetesplayground-test1234/providers/Microsoft.OperationalInsights/workspaces/law-test1234"
      workspace_id = "00000000-0000-0000-0000-000000000008"
    }
  }

}

mock_provider "random" {
  override_during = plan

  mock_resource "random_string" {
    defaults = {
      result = "test1234"
    }
  }
}

override_module {
  target = module.kubernetes_service
  outputs = {
    id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurekubernetesplayground-test1234/providers/Microsoft.ContainerService/managedClusters/aks-azurekubernetesplayground-test1234"
    name                       = "aks-azurekubernetesplayground-test1234"
    fqdn                       = "aks-azurekubernetesplayground-test1234.japaneast.azmk8s.io"
    current_kubernetes_version = "1.35.2"
    oidc_issuer_url            = "https://japaneast.oic.prod-aks.azure.com/00000000-0000-0000-0000-000000000000/00000000-0000-0000-0000-000000000001/"
    kubelet_identity_object_id = "00000000-0000-0000-0000-000000000003"
    identity_principal_id      = "00000000-0000-0000-0000-000000000006"
    node_resource_group        = "rg-aks-azurekubernetesplayground-test1234-nodes"
    node_resource_group_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-aks-azurekubernetesplayground-test1234-nodes"
    user_node_pools = {
      user = {
        id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ContainerService/managedClusters/aks-test/agentPools/user"
        name               = "user"
        node_image_version = "AKSAzureLinux-V3gen2-202608.01.0"
      }
    }
    oms_agent_identity = null
  }
}

run "modern_baseline" {
  command = plan

  assert {
    condition = alltrue([
      var.location == "japaneast",
      var.kubernetes_version == null,
      var.sku_tier == "Free",
      var.oidc_issuer_enabled,
      var.workload_identity_enabled,
      !var.local_account_disabled,
      var.automatic_upgrade_channel == "stable",
      var.node_os_upgrade_channel == "NodeImage",
      var.image_cleaner_enabled,
      var.image_cleaner_interval_hours == 168,
      var.system_node_pool.node_count == 2,
      var.system_node_pool.vm_size == "Standard_D4s_v5",
      var.system_node_pool.os_sku == "AzureLinux3",
      var.system_node_pool.only_critical_addons_enabled,
      var.user_node_pools["user"].min_count == 1,
      var.user_node_pools["user"].max_count == 3,
      var.network_profile.network_plugin == "azure",
      var.network_profile.network_plugin_mode == "overlay",
      var.network_profile.network_data_plane == "cilium",
      !var.container_insights_enabled,
    ])
    error_message = "The playground defaults must represent the current AKS Standard learning baseline."
  }

  assert {
    condition = alltrue([
      output.resource_group_name == "rg-azurekubernetesplayground-test1234",
      output.acr_login_server == "acrtest1234.azurecr.io",
      output.aks_current_kubernetes_version == "1.35.2",
      output.aks_oidc_issuer_url != null,
      output.aks_node_resource_group == "rg-aks-azurekubernetesplayground-test1234-nodes",
      output.log_analytics_workspace_id == null,
      output.log_analytics_workspace_name == null,
      length(module.log_analytics) == 0,
    ])
    error_message = "The baseline must create the core resources while keeping Container Insights optional."
  }
}

run "container_insights_enabled" {
  command = plan

  variables {
    container_insights_enabled      = true
    log_analytics_retention_in_days = 60
  }

  assert {
    condition = alltrue([
      length(module.log_analytics) == 1,
      module.log_analytics[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-azurekubernetesplayground-test1234/providers/Microsoft.OperationalInsights/workspaces/law-test1234",
      output.log_analytics_workspace_id == module.log_analytics[0].id,
      output.log_analytics_workspace_name == module.log_analytics[0].name,
    ])
    error_message = "Enabling Container Insights must create and expose the reusable Log Analytics workspace."
  }
}
