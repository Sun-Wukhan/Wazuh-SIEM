# Linux VM
resource "azurerm_linux_virtual_machine" "this_vm" {
  name                  = "siem-linux-vm"
  resource_group_name   = azurerm_resource_group.this.name
  location              = azurerm_resource_group.this.location
  size                  = "Standard_D4s_v5"  # 4 vCPUs, 16 GB RAM
  admin_username        = "wazuhuser"
  network_interface_ids = [azurerm_network_interface.this_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64 # above your 50 GB requirement
  }

source_image_reference {
  publisher = "Canonical"
  offer     = "ubuntu-24_04-lts"
  sku       = "server"
  version   = "latest"
}

  admin_ssh_key {
    username   = "wazuhuser"
    public_key = tls_private_key.this_ssh.public_key_openssh
  }

  disable_password_authentication = true
}