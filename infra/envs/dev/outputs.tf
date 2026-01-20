output "hub_rg" { value = azurerm_resource_group.hub.name }
output "spoke_rg" { value = azurerm_resource_group.spoke.name }

output "hub_vnet_id" { value = azurerm_virtual_network.hub.id }
output "spoke_vnet_id" { value = azurerm_virtual_network.spoke.id }

output "hub_bastion_subnet_id" { value = azurerm_subnet.hub_bastion.id }
output "hub_firewall_subnet_id" { value = azurerm_subnet.hub_firewall.id }

output "spoke_appgw_subnet_id" { value = azurerm_subnet.spoke_appgw.id }
output "spoke_app_subnet_id" { value = azurerm_subnet.spoke_app.id }

output "firewall_private_ip" {
  value = azurerm_firewall.this.ip_configuration[0].private_ip_address
}
output "appgw_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}