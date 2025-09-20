# Virtual Network
resource "azurerm_virtual_network" "this_vnet" {
  name                = "vnet-siem"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

# Subnet
resource "azurerm_subnet" "this_subnet" {
  name                 = "subnet-siem"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "this_public_ip" {
  name                = "siem-vm-ip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
}

# Network Security Group (SSH locked down)
resource "azurerm_network_security_group" "this_nsg" {
  name                = "nsg-siem"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "142.113.208.29"  # Replace with your VPN range for ADR
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Wazuh-Dashboard-HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "142.113.208.29"  # Same IP restriction as SSH
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Wazuh-API"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "55000"
    source_address_prefix      = "142.113.208.29"  # Same IP restriction as SSH
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "this_nic" {
  name                = "nic-siem"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this_public_ip.id
  }
}

# Associate Network Security Group with Network Interface
resource "azurerm_network_interface_security_group_association" "this_nsg_association" {
  network_interface_id      = azurerm_network_interface.this_nic.id
  network_security_group_id = azurerm_network_security_group.this_nsg.id
}

# SSH Key Pair
resource "tls_private_key" "this_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}