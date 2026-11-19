output "vnet_id" {
  value = azurerm_virtual_network.vnet_lab.id
}

output "subnet_id" {
  value = azurerm_subnet.subnet_servers.id
}