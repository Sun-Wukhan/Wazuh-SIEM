# Sensitive outputs
output "ssh_private_key" {
  value     = tls_private_key.this_ssh.private_key_pem
  sensitive = true
}

output "ssh_private_key_openssh" {
  value     = tls_private_key.this_ssh.private_key_openssh
  sensitive = true
}

output "vm_public_ip" {
  value = azurerm_public_ip.this_public_ip.ip_address
}

output "wazuh_dashboard_url" {
  value = "https://${azurerm_public_ip.this_public_ip.ip_address}"
  description = "Wazuh Dashboard URL (default credentials: admin / SecretPassword)"
}