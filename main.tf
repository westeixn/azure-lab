terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "sttfstatelab999"
  container_name       = "tfstate"
  key                  = "lab.terraform.tfstate"
}
}

provider "azurerm" {
  features {}
}

# 1. Resource Group
resource "azurerm_resource_group" "rg_lab" {
  name     = "rg-lab-profissional"
  location = var.location
}

### 2. Network Module
module "network" {
  source              = "./modules/network"
  location            = azurerm_resource_group.rg_lab.location
  resource_group_name = azurerm_resource_group.rg_lab.name
  vnet_cidr           = var.vnet_cidr
  subnet_cidr         = var.subnet_cidr
  allowed_ssh_ip      = var.allowed_ssh_ip
}

# 6. IP Publico
resource "azurerm_public_ip" "pip_lab" {
  name                = "pip-vm-linux"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_lab.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 7. Placa de Rede (NIC) conectada na Subnet e no IP Publico
resource "azurerm_network_interface" "nic_lab" {
  name                = "nic-vm-linux"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_lab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.network.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_lab.id
  }
}
# 8. Maquina Virtual Linux (Ubuntu 22.04 LTS)
resource "azurerm_linux_virtual_machine" "vm_lab" {
  name                            = "vm-ubuntu-lab"
  resource_group_name             = azurerm_resource_group.rg_lab.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.username_vm
  admin_password                  = var.password_vm
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic_lab.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>Azure Lab - Provisioned via Terraform & Cloud-Init</h1>" > /var/www/html/index.html
  EOF
  )
}