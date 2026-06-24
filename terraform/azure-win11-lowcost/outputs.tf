output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.vm.name
}

output "vm_size" {
  value = azurerm_windows_virtual_machine.vm.size
}

output "public_ip_address" {
  value = azurerm_public_ip.pip.ip_address
}

output "rdp_command_windows" {
  value = "mstsc /v:${azurerm_public_ip.pip.ip_address}"
}

output "macos_connection_note" {
  value = "Use Microsoft Remote Desktop for macOS and connect to the public_ip_address output."
}

output "deallocate_command" {
  value = "az vm deallocate --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_windows_virtual_machine.vm.name}"
}
