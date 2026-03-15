output "resource_group_name" {
  value = azurerm_resource_group.mta_rg.name
}

output "load_balancer_public_ip" {
  value = azurerm_public_ip.mta_public_ip.ip_address
}