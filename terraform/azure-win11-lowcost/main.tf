terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # Conservative v4 constraint. Run `terraform init -upgrade` to use the latest compatible v4 release.
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  name_prefix = "win11-us-lowcost-${random_string.suffix.result}"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = [var.vnet_address_space]

  tags = var.tags

  timeouts {
    create = "30m"
    read   = "5m"
    delete = "30m"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes = [var.subnet_address_prefix]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = var.tags

  timeouts {
    create = "30m"
    read   = "5m"
    delete = "30m"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP-From-Brazil-IP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.allowed_rdp_ip
    destination_address_prefix = "*"
  }

  tags = var.tags

  timeouts {
    create = "30m"
    read   = "5m"
    delete = "30m"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "vm-${local.name_prefix}"
  computer_name = "win11us"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size           = var.vm_size
  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    name                 = "osdisk-${local.name_prefix}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = 127
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = var.windows_11_sku
    version   = "latest"
  }

  # Required for Windows client OS licensing on Azure.
  license_type = "Windows_Client"

  ### enable_automatic_updates = true
  automatic_updates_enabled = true  
  patch_mode               = "AutomaticByOS"

  tags = merge(var.tags, {
    os          = "windows-11"
    region      = "us"
    access_from = "brazil"
    cost        = "low"
  })

  depends_on = [
    azurerm_network_interface_security_group_association.nic_nsg
  ]
}
