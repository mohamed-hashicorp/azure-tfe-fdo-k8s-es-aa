# Azure Managed Redis (AMR) — uses SKUs like ComputeOptimized_X1/X3, MemoryOptimized_M10.
# This is distinct from Azure Cache for Redis (which uses Basic/Standard/Premium SKUs).
# Azure managed Redis does not support numbered databases, so a separate instance is
# required for Sidekiq (TFE docs requirement for Azure deployments).

resource "azurerm_managed_redis" "tfe" {
  name                = "${var.prefix}-redis"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = var.redis_sku

  high_availability_enabled = false

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
    clustering_policy                  = "NoCluster"
  }
}

resource "azurerm_managed_redis" "tfe_sidekiq" {
  name                = "${var.prefix}-redis-sidekiq"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = var.redis_sku

  high_availability_enabled = false

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
    clustering_policy                  = "NoCluster"
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

resource "azurerm_private_endpoint" "redis_sidekiq" {
  name                = "${var.prefix}-redis-sidekiq-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.redis_sidekiq.id

  private_service_connection {
    name                           = "${var.prefix}-redis-sidekiq-psc"
    private_connection_resource_id = azurerm_managed_redis.tfe_sidekiq.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.prefix}-redis-sidekiq-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}
