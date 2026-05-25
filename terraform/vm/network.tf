resource "azurerm_virtual_network" "vnet" {

  name                = "prod-vnet"

  location            = var.location

  resource_group_name = var.resource_group_name

  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {

  name                 = "prod-subnet"

  resource_group_name  = var.resource_group_name

  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {

  name                = "prod-pip"

  location            = var.location

  resource_group_name = var.resource_group_name

  allocation_method   = "Static"

  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg" {

  name                = "prod-nsg"

  location            = var.location

  resource_group_name = var.resource_group_name

  security_rule {

    name                       = "AllowSSH"

    priority                   = 100

    direction                  = "Inbound"

    access                     = "Allow"

    protocol                   = "Tcp"

    source_port_range          = "*"

    destination_port_range     = "22"

    source_address_prefix      = "*"

    destination_address_prefix = "*"
  }

  security_rule {

    name                       = "AllowHTTP"

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

resource "azurerm_network_interface" "nic" {

  name                = "prod-nic"

  location            = var.location

  resource_group_name = var.resource_group_name

  ip_configuration {

    name                          = "internal"

    subnet_id                     = azurerm_subnet.subnet.id

    private_ip_address_allocation = "Dynamic"

    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {

  network_interface_id      = azurerm_network_interface.nic.id

  network_security_group_id = azurerm_network_security_group.nsg.id
}
