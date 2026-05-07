resource "azurerm_postgresql_flexible_server" "tfe" {
  name                          = "${var.prefix}-postgres"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "15"
  delegated_subnet_id           = azurerm_subnet.database.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  administrator_login           = var.tfe_database_username
  administrator_password        = var.tfe_database_password
  zone                          = "2"

  storage_mb = 32768
  sku_name   = "GP_Standard_D2s_v3"

  # The server must be created after the private DNS zone VNet link exists,
  # otherwise Azure cannot resolve the private DNS zone during provisioning.
  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_postgresql_flexible_server_database" "tfe" {
  name      = var.tfe_db_name
  server_id = azurerm_postgresql_flexible_server.tfe.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Enable the PostgreSQL extensions that TFE requires.
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.tfe.id
  value     = "CITEXT,HSTORE,UUID-OSSP,PG_TRGM"
}
