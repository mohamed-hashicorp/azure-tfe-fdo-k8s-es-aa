output "tfe_url" {
  description = "TFE application URL"
  value       = "https://${var.dns_record}"
}

output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config" {
  description = "AKS raw kubeconfig — pipe to kubectl or save to ~/.kube/config"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_connect_command" {
  description = "Run this command to configure kubectl for the new AKS cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
}

output "postgres_fqdn" {
  description = "PostgreSQL Flexible Server FQDN"
  value       = azurerm_postgresql_flexible_server.tfe.fqdn
}

output "storage_account_name" {
  description = "Azure Storage Account name for TFE object storage"
  value       = azurerm_storage_account.tfe.name
}

output "redis_hostname" {
  description = "Azure Managed Redis hostname (main)"
  value       = azurerm_managed_redis.tfe.hostname
}

output "redis_sidekiq_hostname" {
  description = "Azure Managed Redis hostname (Sidekiq)"
  value       = azurerm_managed_redis.tfe_sidekiq.hostname
}

output "tfe_lb_ip" {
  description = "External IP of the TFE Kubernetes LoadBalancer service"
  value       = local.tfe_lb_ip
}
