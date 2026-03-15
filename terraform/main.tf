# 1. Resource Group
resource "azurerm_resource_group" "mta_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Production"
    Project     = "MTA-OMNY-Scalability"
  }
}

# 2. Virtual Network
resource "azurerm_virtual_network" "mta_vnet" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name
}

# 3. Subnet
resource "azurerm_subnet" "mta_subnet" {
  name                 = "internal-subnet"
  resource_group_name  = azurerm_resource_group.mta_rg.name
  virtual_network_name = azurerm_virtual_network.mta_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Public IP
resource "azurerm_public_ip" "mta_public_ip" {
  name                = "${var.project_name}-pip"
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5. Load Balancer
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

# 6. Backend Pool
resource "azurerm_lb_backend_address_pool" "mta_bepool" {
  loadbalancer_id = azurerm_lb.mta_lb.id
  name            = "BackEndAddressPool"
}

# 7. Health Probe (Проверяет 80 порт)
resource "azurerm_lb_probe" "mta_probe" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.mta_lb.id
  protocol        = "Tcp"
  port            = 80
}

# 8. Load Balancer Rule (Перенаправляет трафик с IP на сервера)
resource "azurerm_lb_rule" "mta_lbrule_http" {
  loadbalancer_id                = azurerm_lb.mta_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.mta_bepool.id]
  probe_id                       = azurerm_lb_probe.mta_probe.id
  frontend_ip_configuration_name = "PublicIPAddress"
}

# 9. Network Security Group (Файрвол: открывает 80 порт)
resource "azurerm_network_security_group" "mta_nsg" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.mta_rg.location
  resource_group_name = azurerm_resource_group.mta_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 10. Привязка Файрвола к Подсети
resource "azurerm_subnet_network_security_group_association" "mta_nsg_assoc" {
  subnet_id                 = azurerm_subnet.mta_subnet.id
  network_security_group_id = azurerm_network_security_group.mta_nsg.id
}

# 11. VM Scale Set
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

  # Скрипт автоматической установки Docker и запуска Nginx
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    docker run -d -p 80:80 --name omny-api --restart always nginx
    EOF
  )

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