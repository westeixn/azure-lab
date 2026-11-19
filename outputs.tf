output "vnet_id" {
  value = module.network.vnet_id
}

output "subnet_id" {
  value = module.network.subnet_id
}

output "ip_privado_da_nic" {
  value = azurerm_network_interface.nic_lab.private_ip_address
}

output "ip_publico_da_nic" {
  value = azurerm_public_ip.pip_lab.ip_address
}