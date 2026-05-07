# Storage account name rules: 3-24 chars, lowercase letters and numbers only, globally unique.
# We strip hyphens from the prefix and append "tfe" to keep it identifiable.
resource "azurerm_storage_account" "tfe" {
  name                     = substr("${replace(lower(var.prefix), "-", "")}tfe", 0, 24)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_storage_container" "tfe" {
  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.tfe.id
  container_access_type = "private"
}
