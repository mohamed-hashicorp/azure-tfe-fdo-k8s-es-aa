resource "kubernetes_namespace" "tfe" {
  metadata {
    name = "terraform-enterprise"
  }
}

# Image pull secret for the HashiCorp container registry.
# TFE FDO images are hosted at images.releases.hashicorp.com and require
# the license key as the password to authenticate.
resource "kubernetes_secret" "registry" {
  metadata {
    name      = "terraform-enterprise"
    namespace = kubernetes_namespace.tfe.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "images.releases.hashicorp.com" = {
          username = "terraform"
          password = var.tfe_license
          auth     = base64encode("terraform:${var.tfe_license}")
        }
      }
    })
  }
}

# TLS secret containing the Let's Encrypt certificate chain and private key.
# The full chain (cert + issuer) is required for browsers to trust the certificate.
resource "kubernetes_secret" "tfe_tls" {
  metadata {
    name      = "tfe-tls"
    namespace = kubernetes_namespace.tfe.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = "${acme_certificate.tfe.certificate_pem}${acme_certificate.tfe.issuer_pem}"
    "tls.key" = acme_certificate.tfe.private_key_pem
  }

  depends_on = [acme_certificate.tfe]
}

# Sensitive TFE configuration passed as a Kubernetes secret and referenced
# via secretRefs in the Helm values — keeps secrets out of the ConfigMap.
resource "kubernetes_secret" "tfe_secrets" {
  metadata {
    name      = "tfe-secrets"
    namespace = kubernetes_namespace.tfe.metadata[0].name
  }

  data = {
    TFE_LICENSE             = var.tfe_license
    TFE_ENCRYPTION_PASSWORD = var.tfe_encryption_password
    TFE_DATABASE_PASSWORD   = var.tfe_database_password

    # Storage account key for TFE object storage (Azure Blob)
    TFE_OBJECT_STORAGE_AZURE_ACCOUNT_KEY = azurerm_storage_account.tfe.primary_access_key

    TFE_REDIS_PASSWORD = azurerm_managed_redis.tfe.default_database[0].primary_access_key
  }

  # The Kubernetes provider cannot reconcile data entries that are both sensitive
  # and computed (unknown at plan time). Explicit depends_on ensures Azure resources
  # are fully created and their values are known before this secret is planned.
  depends_on = [
    azurerm_storage_account.tfe,
    azurerm_managed_redis.tfe,
  ]
}
