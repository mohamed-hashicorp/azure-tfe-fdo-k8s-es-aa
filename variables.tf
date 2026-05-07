variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region for Route53 DNS challenge"
  type        = string
}

variable "acme_server_url" {
  description = "ACME server URL (Let's Encrypt production or staging)"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com)"
  type        = string
}

variable "dns_record" {
  description = "Full FQDN for the TFE instance (e.g., tfe.example.com)"
  type        = string
}

variable "email" {
  description = "Email address for ACME registration"
  type        = string
}

variable "tfe_image_tag" {
  description = "TFE Docker image version (e.g., 1.2.2 — used as v1.2.2 image tag)"
  type        = string
}

variable "helm_chart_version" {
  description = "hashicorp/terraform-enterprise Helm chart version (see https://helm.releases.hashicorp.com)"
  type        = string
  default     = "1.6.7"
}

variable "tfe_license" {
  description = "TFE license key"
  type        = string
  sensitive   = true
}

variable "tfe_encryption_password" {
  description = "TFE encryption password"
  type        = string
  sensitive   = true
}

variable "tfe_admin_password" {
  description = "TFE initial admin password"
  type        = string
  sensitive   = true
}

variable "tfe_database_password" {
  description = "TFE PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "tfe_database_username" {
  description = "TFE PostgreSQL admin username"
  type        = string
  default     = "tfeadmin"
}

variable "tfe_db_name" {
  description = "TFE database name"
  type        = string
  default     = "tfedb"
}

variable "blob_container_name" {
  description = "Azure Blob Storage container name for TFE object storage"
  type        = string
}

variable "redis_sku" {
  description = "Azure Managed Redis SKU (e.g., ComputeOptimized_X1, ComputeOptimized_X3, MemoryOptimized_M10)"
  type        = string
  default     = "ComputeOptimized_X3"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS default node pool"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for the AKS default node pool. Minimum Standard_D8s_v3 for TFE's default 4000m CPU request to fit alongside system pods."
  type        = string
  default     = "Standard_D8s_v3"
}

# Retained for backwards compatibility with existing tfvars; not used in K8s deployments.
variable "certs_dir" {
  description = "TFE certs directory (VM deployments only)"
  type        = string
  default     = ""
}

variable "data_dir" {
  description = "TFE data directory (VM deployments only)"
  type        = string
  default     = ""
}
