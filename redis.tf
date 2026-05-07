# Azure Managed Redis (AMR) — uses SKUs like ComputeOptimized_X1/X3, MemoryOptimized_M10.
# This is distinct from Azure Cache for Redis (which uses Basic/Standard/Premium SKUs).
resource "azurerm_managed_redis" "tfe" {
  name                = "${var.prefix}-redis"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = var.redis_sku

  default_database {
    # Encrypted = TLS-only connections (required by Azure Managed Redis).
    client_protocol = "Encrypted"
    # EnterpriseCluster presents a single-endpoint interface and hides the
    # internal cluster topology. OSSCluster exposes it, causing MOVED errors
    # in non-cluster-aware clients such as asynq (used by TFE).
    clustering_policy                  = "EnterpriseCluster"
    access_keys_authentication_enabled = true
  }
}

# Private endpoint keeps Redis off the public internet and reachable only from the VNet.
resource "azurerm_private_endpoint" "redis" {
  name                = "${var.prefix}-redis-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.redis.id

  private_service_connection {
    name                           = "${var.prefix}-redis-psc"
    private_connection_resource_id = azurerm_managed_redis.tfe.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.prefix}-redis-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}
