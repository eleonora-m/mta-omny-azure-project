# Resource Group
resource "azurerm_resource_group" "mta_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Production"
    Project     = "MTA-OMNY-Scalability"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "mta_vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name
}

# Subnet
resource "azurerm_subnet" "mta_subnet" {
  name                 = "internal-subnet"
  resource_group_name  = azurerm_resource_group.mta_rg.name
  virtual_network_name = azurerm_virtual_network.mta_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Public IP
resource "azurerm_public_ip" "mta_public_ip" {
  name                = "${var.project_name}-pip"
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Load Balancer
resource "azurerm_lb" "mta_lb" {
  name                = "${var.project_name}-lb"
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.mta_public_ip.id
  }
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "mta_bepool" {
  loadbalancer_id = azurerm_lb.mta_lb.id
  name            = "BackEndAddressPool"
}

# Health Probe
resource "azurerm_lb_probe" "mta_probe" {
  name            = "tcp-probe"
  loadbalancer_id = azurerm_lb.mta_lb.id
  protocol        = "Tcp"
  port            = 22
}

# VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "mta_vmss" {

  name                = "${var.project_name}-vmss"
  resource_group_name = azurerm_resource_group.mta_rg.name
  location            = azurerm_resource_group.mta_rg.location

  sku       = "Standard_D2s_v3"
  instances = 1

  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "omny-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.mta_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.mta_bepool.id]
    }
  }
}