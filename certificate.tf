# ---------------------------------------------------------------------------
# ACME / Let's Encrypt certificate via Route53 DNS-01 challenge
# ---------------------------------------------------------------------------

resource "tls_private_key" "acme_account" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "acme_registration" "tfe" {
  account_key_pem = tls_private_key.acme_account.private_key_pem
  email_address   = var.email
}

data "aws_route53_zone" "tfe" {
  name         = "${var.hosted_zone_name}."
  private_zone = false
}

# DNS-01 challenge: ACME creates a TXT record in Route53 to prove domain ownership.
# No web server or public IP is required — suitable for use before AKS is ready.
resource "acme_certificate" "tfe" {
  account_key_pem = acme_registration.tfe.account_key_pem
  common_name     = var.dns_record

  dns_challenge {
    provider = "route53"
    config = {
      AWS_DEFAULT_REGION      = var.aws_region
      AWS_HOSTED_ZONE_ID      = data.aws_route53_zone.tfe.zone_id
      AWS_POLLING_INTERVAL    = "10"
      AWS_PROPAGATION_TIMEOUT = "180"
    }
  }
}

# ---------------------------------------------------------------------------
# Route53 A record pointing to the TFE Kubernetes LoadBalancer
# Created after the Helm release so the LB IP is available.
# ---------------------------------------------------------------------------
data "kubernetes_service" "tfe_lb" {
  metadata {
    name      = "terraform-enterprise"
    namespace = kubernetes_namespace.tfe.metadata[0].name
  }

  # Defer this data source to apply time so the LoadBalancer IP is assigned
  # before Terraform tries to read it.
  depends_on = [
    helm_release.tfe,
    kubernetes_namespace.tfe,
  ]
}

locals {
  tfe_lb_ip = data.kubernetes_service.tfe_lb.status[0].load_balancer[0].ingress[0].ip
}

resource "aws_route53_record" "tfe" {
  zone_id = data.aws_route53_zone.tfe.zone_id
  name    = var.dns_record
  type    = "A"
  ttl     = 60
  records = [local.tfe_lb_ip]
}
