resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# AKS node subnet
resource "azurerm_subnet" "aks" {
  name                 = "${var.prefix}-aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# PostgreSQL Flexible Server subnet — must be delegated exclusively to PostgreSQL
resource "azurerm_subnet" "database" {
  name                 = "${var.prefix}-db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "fs"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Redis private endpoint subnet — network policies must be disabled for private endpoints
resource "azurerm_subnet" "redis" {
  name                              = "${var.prefix}-redis-subnet"
  resource_group_name               = azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = ["10.0.3.0/24"]
  private_endpoint_network_policies = "Disabled"
}

# ---------------------------------------------------------------------------
# Private DNS zone for PostgreSQL Flexible Server (VNet integration / private access)
# The zone name suffix must end with .postgres.database.azure.com per Azure requirements.
# ---------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.prefix}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "${var.prefix}-postgres-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

# ---------------------------------------------------------------------------
# Private DNS zone for Azure Managed Redis private endpoint
# ---------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "${var.prefix}-redis-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}
