provider "azuread" {
  version = "=0.7.0"
}

provider "random" {
  version = "~>2.2"
}

module "serviceprincipal" {
  source = "./modules/service-principal"
  service_principal_end_data = "2020-12-31T23:59:59Z"
  providers = {
    azuread = azuread
    randon = random
  }
}

module "virtual-network" {
  source = "./modules/virtual-network"
  name = var.cluster_name
  location = var.location
  resource-group-name = azurerm_resource_group.k8s.name
  virtual-network-address-space = ["10.240.0.0/16"]
  subnet-address-prefixes = ["10.240.0.0/16"] 
  service_principal_application_id = module.serviceprincipal.service_principal_application_id
  custom_tags = var.custom_tags
}

module "log-analytics" {
  source = "./modules/log-analytics"
  use_azure_monitor = var.use_azure_monitor
  resource_group_name = "${var.resource_group_name}-loganalytics-group"
  location = var.location
  log_analytics_workspace_sku = var.log_analytics_workspace_sku
  cluster_name = var.cluster_name
  custom_tags = var.custom_tags
}

module kubernetes-cluster {
  source = "./modules/kubernetes-clustes"
  agent_count = var.agent_count
  kubernetes_version = var.kubernetes_version
  ssh_public_key = var.ssh_public_key
  dns_prefix = var.dns_prefix
  cluster_name = var.cluster_name
  default_node_pool_vm_size = var.default_node_pool_vm_size
  default_node_pool_disk_size = var.default_node_pool_disk_size
  vnet_subnet_id = module.virtual-network.subnet-id
  service-principal = {
    client-id = module.serviceprincipal.application_id
    client-secret = module.serviceprincipal.password
  }
  resource_group_name = azurerm_resource_group.k8s.name
  location = var.location
  azuremonitor = {
    use_azure_monitor = var.use_azure_monitor
    log_analytics_workspace_id = module.log-analytics.workspace-id
  }
  custom_tags = var.custom_tags
}
