# 1. Create a Resource Group
resource "azurerm_resource_group" "mta_rg" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    Environment = "Production"
    Project     = "MTA-OMNY-Scalability"
  }
}

# 2. Create a Virtual Network (VNet)
resource "azurerm_virtual_network" "mta_vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name
}

# 3. Create a Subnet
resource "azurerm_subnet" "mta_subnet" {
  name                 = "internal-subnet"
  resource_group_name  = azurerm_resource_group.mta_rg.name
  virtual_network_name = azurerm_virtual_network.mta_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Create a Public IP (Standard SKU to fix the Azure Free Tier limit)
resource "azurerm_public_ip" "mta_public_ip" {
  name                = "${var.project_name}-pip"
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # <-- ИМЕННО ЭТО ИСПРАВЛЯЕТ ПЕРВУЮ ОШИБКУ
}

# 5. Create a Load Balancer (Standard SKU required by Standard IP)
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

# 6. Create a Backend Address Pool for the Load Balancer
resource "azurerm_lb_backend_address_pool" "mta_bepool" {
  loadbalancer_id = azurerm_lb.mta_lb.id
  name            = "BackEndAddressPool"
}

# 7. Create the Virtual Machine Scale Set (The auto-scaling servers)
resource "azurerm_linux_virtual_machine_scale_set" "mta_vmss" {
  name                = "${var.project_name}-vmss"
  resource_group_name = azurerm_resource_group.mta_rg.name
  location            = azurerm_resource_group.mta_rg.location
  sku                 = "Standard_B1s"
  instances           = 2

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