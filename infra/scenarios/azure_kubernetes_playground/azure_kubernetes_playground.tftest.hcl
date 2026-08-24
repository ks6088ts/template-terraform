mock_provider "azurerm" {
  override_during = plan

  mock_resource "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azurekubernetesplayground-test1234"
      name     = "azurekubernetesplayground-test1234"
      location = "japaneast"
    }
  }

  mock_resource "azurerm_container_registry" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azurekubernetesplayground-test1234/providers/Microsoft.ContainerRegistry/registries/azurekubernetesplaygroundtest1234"
      name         = "azurekubernetesplaygroundtest1234"
      login_server = "crazurekubernetesplaygroundtest1234.azurecr.io"
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
    id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/azurekubernetesplayground-test1234/providers/Microsoft.ContainerService/managedClusters/aks-azurekubernetesplayground-test1234"
    name                = "aks-azurekubernetesplayground-test1234"
    fqdn                = "aks-azurekubernetesplayground-test1234.hcp.japaneast.azmk8s.io"
    kube_config_raw     = "apiVersion: v1"
    node_resource_group = "rg-aks-azurekubernetesplayground-test1234-nodes"
  }
}

run "workshop_baseline_is_deployed_by_default" {
  command = plan

  assert {
    condition = alltrue([
      var.location == "japaneast",
      var.node_count == 1,
      var.vm_size == "Standard_B2s_v2",
      var.network_plugin == "kubenet",
    ])
    error_message = "The Kubernetes workshop must preserve the one-node B2s_v2 baseline."
  }

  assert {
    condition = alltrue([
      output.resource_group_name == "rg-azurekubernetesplayground-test1234",
      output.acr_name == "crazurekubernetesplaygroundtest1234",
      output.acr_login_server == "crazurekubernetesplaygroundtest1234.azurecr.io",
      output.aks_name == "aks-azurekubernetesplayground-test1234",
      output.aks_node_resource_group == "rg-aks-azurekubernetesplayground-test1234-nodes",
    ])
    error_message = "The workshop scripts require stable resource group, ACR, and AKS outputs."
  }
}
