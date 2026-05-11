resource "helm_release" "tfe" {
  name             = "terraform-enterprise"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "terraform-enterprise"
  version          = var.helm_chart_version
  namespace        = kubernetes_namespace.tfe.metadata[0].name
  create_namespace = false
  timeout          = 600

  values = [
    templatefile("${path.module}/values.yaml", {
      # Image
      tfe_image_tag = var.tfe_image_tag

      # The registry secret holds docker credentials where the TFE license key
      # is the password used to authenticate against images.releases.hashicorp.com
      registry_secret = kubernetes_secret.registry.metadata[0].name

      # TLS
      tls_secret   = kubernetes_secret.tfe_tls.metadata[0].name
      ca_cert_data = base64encode(acme_certificate.tfe.issuer_pem)

      # Sensitive TFE config (license, encryption password, DB password, storage key, Redis URL)
      tfe_secrets = kubernetes_secret.tfe_secrets.metadata[0].name

      # TFE environment variables
      dns_record           = var.dns_record
      db_host              = azurerm_postgresql_flexible_server.tfe.fqdn
      db_name              = var.tfe_db_name
      db_user              = var.tfe_database_username
      storage_account_name = azurerm_storage_account.tfe.name
      storage_container    = azurerm_storage_container.tfe.name

      # Redis — host:port only; passwords flow in via tfe-secrets
      redis_host         = "${azurerm_managed_redis.tfe.hostname}:${azurerm_managed_redis.tfe.default_database[0].port}"
      redis_sidekiq_host = "${azurerm_managed_redis.tfe_sidekiq.hostname}:${azurerm_managed_redis.tfe_sidekiq.default_database[0].port}"
    })
  ]

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_postgresql_flexible_server_database.tfe,
    azurerm_postgresql_flexible_server_configuration.extensions,
    azurerm_managed_redis.tfe,
    azurerm_managed_redis.tfe_sidekiq,
    azurerm_private_endpoint.redis,
    azurerm_private_endpoint.redis_sidekiq,
    kubernetes_secret.tfe_secrets,
    kubernetes_secret.tfe_tls,
    kubernetes_secret.registry,
  ]
}
