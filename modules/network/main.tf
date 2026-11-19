### Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet_lab" {
  name                = "vnet-corporativa"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_cidr
}

### Subnet (VLAN)
resource "azurerm_subnet" "subnet_servers" {
  name                 = "subnet-servidores"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet_lab.name
  address_prefixes     = var.subnet_cidr
}

### Firewall (NSG)
resource "azurerm_network_security_group" "nsg_lab" {
  name                = "nsg-servidores"
  location            = var.location
  resource_group_name = var.resource_group_name

 security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

### Associacao NSG -> Subnet
resource "azurerm_subnet_network_security_group_association" "associacao_lab" {
  subnet_id                 = azurerm_subnet.subnet_servers.id
  network_security_group_id = azurerm_network_security_group.nsg_lab.id
}