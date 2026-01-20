locals {
  hub_vnet_name   = "hub-vnet-${var.env}"
  spoke_vnet_name = "spoke-app-vnet-${var.env}"

  appgw_backend_pool_id = one([
    for p in azurerm_application_gateway.this.backend_address_pool : p.id
    if p.name == "be-pool-vmss"
  ])

}

resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-network-${var.env}"
  location = var.location
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-spoke-app-${var.env}"
  location = var.location
}

# HUB VNET
resource "azurerm_virtual_network" "hub" {
  name                = local.hub_vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.10.0/27"]
}

resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.20.0/26"]
}

# SPOKE VNET
resource "azurerm_virtual_network" "spoke" {
  name                = local.spoke_vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "spoke_appgw" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.10.0/24"]
}

resource "azurerm_subnet" "spoke_app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.1.0/24"]
}

# PEERING
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke-${var.env}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub-${var.env}"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_public_ip" "firewall" {
  name                = "pip-azure-firewall-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "this" {
  name                = "azure-firewall-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_route_table" "spoke_egress" {
  name                = "rt-spoke-egress-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
}

resource "azurerm_route" "default_to_firewall" {
  name                   = "default-to-firewall"
  resource_group_name    = azurerm_resource_group.spoke.name
  route_table_name       = azurerm_route_table.spoke_egress.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "app_subnet" {
  subnet_id      = azurerm_subnet.spoke_app.id
  route_table_id = azurerm_route_table.spoke_egress.id
}

# App Gateway Public IP
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NSG for app subnet: allow ONLY AppGW subnet -> app subnet on 80
resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name

  security_rule {
    name                       = "allow-http-from-appgw-subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.1.10.0/24" # appgw-subnet
    destination_address_prefix = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.spoke_app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Application Gateway (WAF_v2)
resource "azurerm_application_gateway" "this" {
  name                = "appgw-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name

  backend_address_pool {
    name = "be-pool-vmss"
  }
  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Detection"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.spoke_appgw.id
  }

  frontend_port {
    name = "fe-port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "fe-public"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }



  probe {
    name                                      = "probe-http"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200-399"]
    }
  }


  backend_http_settings {
    name                  = "be-http-settings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    probe_name            = "probe-http"
    host_name             = "localhost"
  }

  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "fe-public"
    frontend_port_name             = "fe-port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule-http"
    rule_type                  = "Basic"
    http_listener_name         = "listener-http"
    backend_address_pool_name  = "be-pool-vmss"
    backend_http_settings_name = "be-http-settings"
    priority                   = 100
  }
}

# Firewall allow rule so VMSS can install nginx via forced tunneling
resource "azurerm_firewall_application_rule_collection" "allow_vm_updates" {
  name                = "arc-allow-vm-updates-${var.env}"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = azurerm_resource_group.hub.name
  priority            = 100
  action              = "Allow"

  rule {
    name             = "allow-ubuntu-repos"
    source_addresses = ["10.1.1.0/24"]

    protocol {
      type = "Http"
      port = 80
    }

    protocol {
      type = "Https"
      port = 443
    }

    target_fqdns = [
      "azure.archive.ubuntu.com",
      "archive.ubuntu.com",
      "security.ubuntu.com"
    ]
  }
}


# VM Scale Set (private), integrated into AppGW backend pool
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-nginx-${var.env}"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke.name

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  sku       = "Standard_B2s"
  instances = 2

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("${path.root}/${var.ssh_public_key_path}")

  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.spoke_app.id

      application_gateway_backend_address_pool_ids = [
        local.appgw_backend_pool_id
      ]
    }
  }

  custom_data = base64encode(<<EOF
#!/bin/bash
set -e
apt-get update -y
apt-get install -y nginx
cat >/var/www/html/index.html <<HTML
<h1>Private Edge Gateway</h1>
<p>Served from VMSS behind Application Gateway (no public IPs).</p>
HTML
systemctl enable nginx
systemctl restart nginx
EOF
  )

  depends_on = [
    azurerm_subnet_network_security_group_association.app
  ]

}

