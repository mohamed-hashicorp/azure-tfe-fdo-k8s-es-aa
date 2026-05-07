resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.prefix

  default_node_pool {
    name                        = "default"
    node_count                  = var.aks_node_count
    vm_size                     = var.aks_vm_size
    vnet_subnet_id              = azurerm_subnet.aks.id
    temporary_name_for_rotation = "tmpnp"
  }

  oidc_issuer_enabled = true

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    # Must not overlap with the VNet (10.0.0.0/16) or any subnet
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
