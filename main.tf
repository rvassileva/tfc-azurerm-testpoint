terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_testpoint" {
  name     = "testpoint-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet_testpoint" {
  name                = "test-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_testpoint.location
  resource_group_name = azurerm_resource_group.rg_testpoint.name
}

resource "azurerm_subnet" "subnet_testpoint" {
  name                 = "testpoint-internal"
  resource_group_name = azurerm_resource_group.rg_testpoint.name
  virtual_network_name = azurerm_virtual_network.vnet_testpoint.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "net_int_testpoint" {
  name                = "testpoint-nic"
  location            = azurerm_resource_group.rg_testpoint.location
  resource_group_name = azurerm_resource_group.rg_testpoint.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_testpoint.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm_testpoint" {
  name                = "testpoint-machine"
  resource_group_name = azurerm_resource_group.rg_testpoint.name
  location            = azurerm_resource_group.rg_testpoint.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.net_int_testpoint.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}