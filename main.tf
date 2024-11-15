provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "argyle" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "argyle_vnet" {
  name                = "argyle-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.argyle.location
  resource_group_name = azurerm_resource_group.argyle.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.argyle.name
  virtual_network_name = azurerm_virtual_network.argyle_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "external" {
  name                 = "external"
  resource_group_name  = azurerm_resource_group.argyle.name
  virtual_network_name = azurerm_virtual_network.argyle_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "argyle-nsg"
  location            = azurerm_resource_group.argyle.location
  resource_group_name = azurerm_resource_group.argyle.name

  security_rule {
    name                       = "AllowInboundSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowInboundDNS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowInboundDNS_UDP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowInboundHTTPS"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "argyle_nic" {
  name                = "argyle-nic"
  location            = azurerm_resource_group.argyle.location
  resource_group_name = azurerm_resource_group.argyle.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.argyle.id
  }
}

resource "azurerm_network_interface" "fw_nic" {
  name                = "fw-nic"
  location            = azurerm_resource_group.argyle.location
  resource_group_name = azurerm_resource_group.argyle.name

  ip_configuration {
    name                          = "external"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.fw.id
  }
}

resource "azurerm_public_ip" "argyle" {
  name                = "argyle-pip"
  location            = azurerm_resource_group.argyle.location
  resource_group_name = azurerm_resource_group.argyle.name
  allocation_method   = "Dynamic"
}

resource "azurerm_public_ip" "fw" {
  name                = "fw-pip"
  location            = azurerm_resource_group.argyle.location
  resource_group_name = azurerm_resource_group.argyle.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "fw_nsg" {
  name                = "fw-nsg"
  location            = azurerm_resource_group.argyle.location
  resource_group_name = azurerm_resource_group.argyle.name

  security_rule {
    name                       = "AllowInboundTraffic"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_linux_virtual_machine" "argyle_vm" {
  name                = "argyle-vm"
  resource_group_name = azurerm_resource_group.argyle.name
  location            = azurerm_resource_group.argyle.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.argyle_nic.id,
  ]

  admin_password = var.admin_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-12"
    sku       = "12"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "install_powerdns" {
  name                 = "install-powerdns"
  virtual_machine_id   = azurerm_linux_virtual_machine.argyle_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "fileUris": ["https://path-to-your-installation-script/install-powerdns.sh"],
        "commandToExecute": "./install-powerdns.sh"
    }
SETTINGS
}

resource "azurerm_palo_alto_vnfirewall" "firewall" {
  name                = "firewall"
  resource_group_name = azurerm_resource_group.argyle.name
  location            = azurerm_resource_group.argyle.location
  size                = "Standard_B1ms"
  network_interface_ids = [
    azurerm_network_interface.fw_nic.id,
  ]

  admin_username = var.admin_username
  admin_password = var.admin_password
}
