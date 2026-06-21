output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "vm_name" {
  description = "Name of the Linux VM."
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_id" {
  description = "Resource ID of the Linux VM."
  value       = azurerm_linux_virtual_machine.this.id
}

output "admin_username" {
  description = "Admin username of the Linux VM."
  value       = var.admin_username
}

output "vm_private_ip_address" {
  description = "Private IP address of the Linux VM."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "bastion_name" {
  description = "Name of the Azure Bastion host."
  value       = azurerm_bastion_host.this.name
}

output "bastion_public_ip_address" {
  description = "Public IP address assigned to Azure Bastion."
  value       = azurerm_public_ip.bastion.ip_address
}

output "nat_gateway_id" {
  description = "Resource ID of the NAT Gateway."
  value       = azurerm_nat_gateway.this.id
}

output "nat_gateway_public_ip_address" {
  description = "Public IP address used by NAT Gateway for outbound SNAT."
  value       = azurerm_public_ip.nat.ip_address
}

output "azure_cli_bastion_ssh_example" {
  description = "Example Azure CLI command for SSH through Bastion."
  value       = "az network bastion ssh --name ${azurerm_bastion_host.this.name} --resource-group ${azurerm_resource_group.this.name} --target-resource-id ${azurerm_linux_virtual_machine.this.id} --auth-type ssh-key --username ${var.admin_username} --ssh-key ~/.ssh/id_ed25519"
}
