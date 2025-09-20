# Cloud-init script to install Docker and deploy Wazuh
resource "azurerm_virtual_machine_extension" "wazuh_setup" {
  name                 = "wazuh-docker-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.this_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    script = base64encode(templatefile("${path.module}/scripts/install_wazuh.sh", {
      wazuh_version = "4.13.0"
    }))
  })

  tags = {
    Environment = "Production"
    Application = "SIEM"
  }
}
