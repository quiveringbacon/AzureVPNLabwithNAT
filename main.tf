provider "azurerm" {
  features {
  }
}

#variables
variable "A-location" {
    description = "Location of the resources"
    #default     = "eastus"
}

variable "B-resource_group_name" {
    description = "Name of the resource group to create"
}

variable "C-home_public_ip" {
    description = "Your home public ip address"
}

variable "D-username" {
    description = "Username for Virtual Machines"
    #default     = "azureuser"
}

variable "E-password" {
    description = "Password for Virtual Machines"
    sensitive = true
}

resource "azurerm_resource_group" "RG" {
  location = var.A-location
  name     = var.B-resource_group_name
}

#vnets and subnets
resource "azurerm_virtual_network" "hub-vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.RG.location
  name                = "AZ-hub-vnet"
  resource_group_name = azurerm_resource_group.RG.name
  subnet {
    address_prefix     = "10.0.0.0/24"
    name                 = "default"
    security_group = azurerm_network_security_group.hubvnetNSG.id
  }
  subnet {
    address_prefix     = "10.0.1.0/24"
    name                 = "GatewaySubnet" 
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
}
resource "azurerm_virtual_network" "spoke-vnet" {
  address_space       = ["10.250.0.0/16"]
  location            = azurerm_resource_group.RG.location
  name                = "AZ-spoke-vnet"
  resource_group_name = azurerm_resource_group.RG.name
  subnet {
    address_prefix     = "10.250.0.0/24"
    name                 = "default"
    security_group = azurerm_network_security_group.spokevnetNSG.id
  }
  subnet {
    address_prefix     = "10.250.1.0/24"
    name                 = "GatewaySubnet" 
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

resource "azurerm_virtual_network_peering" "hubtospokepeering" {
  name                      = "hub-to-spoke-peering"
  remote_virtual_network_id = azurerm_virtual_network.spoke-vnet.id
  resource_group_name       = azurerm_resource_group.RG.name
  virtual_network_name      = "AZ-hub-vnet"
  allow_forwarded_traffic = true
  allow_gateway_transit = true
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  depends_on = [
    azurerm_virtual_network.hub-vnet,
    azurerm_virtual_network.spoke-vnet,
    azurerm_virtual_network_gateway.azurevpngw,
  ]
}
resource "azurerm_virtual_network_peering" "spoketohubpeering" {
  name                      = "spoke-to-hub-peering"
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  resource_group_name       = azurerm_resource_group.RG.name
  virtual_network_name      = "AZ-spoke-vnet"
  allow_forwarded_traffic = true
  use_remote_gateways = true
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  depends_on = [
    azurerm_virtual_network.spoke-vnet,
    azurerm_virtual_network.hub-vnet,
    azurerm_virtual_network_gateway.azurevpngw,
  ]
}
resource "azurerm_virtual_network" "onprem-vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.RG.location
  name                = "onprem-vnet"
  resource_group_name = azurerm_resource_group.RG.name
  subnet {
    address_prefix     = "10.0.0.0/24"
    name                 = "default"
    security_group = azurerm_network_security_group.onpremvnetNSG.id
  }
  subnet {
    address_prefix     = "10.0.1.0/24"
    name                 = "GatewaySubnet" 
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}


#NSG's
resource "azurerm_network_security_group" "hubvnetNSG" {
  location            = azurerm_resource_group.RG.location
  name                = "AZ-hub-vnet-default-nsg"
  resource_group_name = azurerm_resource_group.RG.name
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_network_security_rule" "hubvnetnsgrule1" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  direction                   = "Inbound"
  name                        = "AllowCidrBlockRDPInbound"
  network_security_group_name = "AZ-hub-vnet-default-nsg"
  priority                    = 2711
  protocol                    = "Tcp"
  resource_group_name         = azurerm_network_security_group.hubvnetNSG.resource_group_name
  source_address_prefix       = var.C-home_public_ip
  source_port_range           = "*"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}



resource "azurerm_network_security_group" "spokevnetNSG" {
  location            = azurerm_resource_group.RG.location
  name                = "AZ-spoke-vnet-default-nsg"
  resource_group_name = azurerm_resource_group.RG.name
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_network_security_rule" "spokevnetnsgrule1" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  direction                   = "Inbound"
  name                        = "AllowCidrBlockRDPInbound"
  network_security_group_name = "AZ-spoke-vnet-default-nsg"
  priority                    = 2711
  protocol                    = "Tcp"
  resource_group_name         = azurerm_network_security_group.spokevnetNSG.resource_group_name
  source_address_prefix       = var.C-home_public_ip
  source_port_range           = "*"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}


resource "azurerm_network_security_group" "onpremvnetNSG" {
  location            = azurerm_resource_group.RG.location
  name                = "onprem-vnet-default-nsg"
  resource_group_name = azurerm_resource_group.RG.name
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_network_security_rule" "onpremvnetnsgrule1" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  direction                   = "Inbound"
  name                        = "AllowCidrBlockRDPInbound"
  network_security_group_name = "onprem-vnet-default-nsg"
  priority                    = 2711
  protocol                    = "Tcp"
  resource_group_name         = azurerm_network_security_group.onpremvnetNSG.resource_group_name
  source_address_prefix       = var.C-home_public_ip
  source_port_range           = "*"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}



#Public IP's
resource "azurerm_public_ip" "azurevpngw-pip" {
  name                = "azurevpngw-pip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Static"
  sku = "Standard"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_public_ip" "onpremvpngw-pip" {
  name                = "onpremvpngw-pip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Static"
  sku = "Standard"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_public_ip" "hubvm-pip" {
  name                = "hubvm-pip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Dynamic"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_public_ip" "spokevm-pip" {
  name                = "spokevm-pip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Dynamic"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_public_ip" "onpremvm-pip" {
  name                = "onpremvm-pip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Dynamic"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

#VPN Gateways
resource "azurerm_virtual_network_gateway" "azurevpngw" {
  name                = "AzVPNGW"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  type     = "Vpn"
  sku           = "VpnGw2"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.azurevpngw-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_virtual_network.hub-vnet.subnet.*.id[1]
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

#nat rules
resource "azurerm_virtual_network_gateway_nat_rule" "egressnat" {
  name                       = "egressNAT"
  resource_group_name        = azurerm_resource_group.RG.name
  virtual_network_gateway_id = azurerm_virtual_network_gateway.azurevpngw.id
  mode                       = "EgressSnat"
  type                       = "Static"
  
  external_mapping {
    address_space = "10.10.0.0/16"
    
  }

  internal_mapping {
    address_space = "10.0.0.0/16"
    
  }
}
resource "azurerm_virtual_network_gateway_nat_rule" "ingressnat" {
  name                       = "ingressNAT"
  resource_group_name        = azurerm_resource_group.RG.name
  virtual_network_gateway_id = azurerm_virtual_network_gateway.azurevpngw.id
  mode                       = "IngressSnat"
  type                       = "Static"
  
  external_mapping {
    address_space = "10.20.0.0/16"
    
  }

  internal_mapping {
    address_space = "10.0.0.0/16"
    
  }
}

resource "azurerm_virtual_network_gateway" "onpremvpngw" {
  name                = "onpremVPNGW"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  type     = "Vpn"
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.onpremvpngw-pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_virtual_network.onprem-vnet.subnet.*.id[1]
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

#Local Network Gateways
resource "azurerm_local_network_gateway" "AZlng" {
  address_space       = ["10.10.0.0/16", "10.250.0.0/16"]
  gateway_address     = azurerm_public_ip.azurevpngw-pip.ip_address
  location            = azurerm_resource_group.RG.location
  name                = "AZlng"
  resource_group_name = azurerm_resource_group.RG.name
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_local_network_gateway" "onpremlng" {
  address_space       = ["10.0.0.0/16"]
  gateway_address     = azurerm_public_ip.onpremvpngw-pip.ip_address
  location            = azurerm_resource_group.RG.location
  name                = "onpremlng"
  resource_group_name = azurerm_resource_group.RG.name
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

#VPN connections
resource "azurerm_virtual_network_gateway_connection" "to-azure" {
  local_network_gateway_id   = azurerm_local_network_gateway.AZlng.id
  location                   = azurerm_resource_group.RG.location
  name                       = "to-azure"
  resource_group_name        = azurerm_resource_group.RG.name
  shared_key                 = "vpn123"
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.onpremvpngw.id
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  depends_on = [ azurerm_virtual_network_gateway_nat_rule.ingressnat ]
}
resource "azurerm_virtual_network_gateway_connection" "to-onprem" {
  local_network_gateway_id   = azurerm_local_network_gateway.onpremlng.id
  location                   = azurerm_resource_group.RG.location
  name                       = "to-onprem"
  resource_group_name        = azurerm_resource_group.RG.name
  shared_key                 = "vpn123"
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.azurevpngw.id
  egress_nat_rule_ids = [azurerm_virtual_network_gateway_nat_rule.egressnat.id]
  ingress_nat_rule_ids = [azurerm_virtual_network_gateway_nat_rule.ingressnat.id]
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  depends_on = [ azurerm_virtual_network_gateway_nat_rule.egressnat ]
}

#vNIC's
resource "azurerm_network_interface" "hubvm-nic" {
  location            = azurerm_resource_group.RG.location
  name                = "hubvm-nic"
  resource_group_name = azurerm_resource_group.RG.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.hubvm-pip.id
    subnet_id                     = azurerm_virtual_network.hub-vnet.subnet.*.id[0]
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_network_interface" "spokevm-nic" {
  location            = azurerm_resource_group.RG.location
  name                = "spokevm-nic"
  resource_group_name = azurerm_resource_group.RG.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spokevm-pip.id
    subnet_id                     = azurerm_virtual_network.spoke-vnet.subnet.*.id[0]
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_network_interface" "onpremvm-nic" {
  location            = azurerm_resource_group.RG.location
  name                = "onpremvm-nic"
  resource_group_name = azurerm_resource_group.RG.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.onpremvm-pip.id
    subnet_id                     = azurerm_virtual_network.onprem-vnet.subnet.*.id[0]
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

#VM's
resource "azurerm_windows_virtual_machine" "hubvm" {
  admin_password        = var.E-password
  admin_username        = var.D-username
  location              = azurerm_resource_group.RG.location
  name                  = "hubvm"
  network_interface_ids = [azurerm_network_interface.hubvm-nic.id]
  resource_group_name   = azurerm_resource_group.RG.name
  size                  = "Standard_B2ms"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_machine_extension" "killhubvmfirewall" {
  auto_upgrade_minor_version = true
  name                       = "killhubvmfirewall"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  virtual_machine_id         = azurerm_windows_virtual_machine.hubvm.id
  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -command \"Set-NetFirewallProfile -Enabled False\""
    }
  SETTINGS
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_windows_virtual_machine" "spokevm" {
  admin_password        = var.E-password
  admin_username        = var.D-username
  location              = azurerm_resource_group.RG.location
  name                  = "spokevm"
  network_interface_ids = [azurerm_network_interface.spokevm-nic.id]
  resource_group_name   = azurerm_resource_group.RG.name
  size                  = "Standard_B2ms"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_machine_extension" "killspokevmfirewall" {
  auto_upgrade_minor_version = true
  name                       = "killspokevmfirewall"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  virtual_machine_id         = azurerm_windows_virtual_machine.spokevm.id
  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -command \"Set-NetFirewallProfile -Enabled False\""
    }
  SETTINGS
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_windows_virtual_machine" "onpremvm" {
  admin_password        = var.E-password
  admin_username        = var.D-username
  location              = azurerm_resource_group.RG.location
  name                  = "onpremvm"
  network_interface_ids = [azurerm_network_interface.onpremvm-nic.id]
  resource_group_name   = azurerm_resource_group.RG.name
  size                  = "Standard_B2ms"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_machine_extension" "killonpremvmfirewall" {
  auto_upgrade_minor_version = true
  name                       = "killonpremvmfirewall"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  virtual_machine_id         = azurerm_windows_virtual_machine.onpremvm.id
  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -command \"Set-NetFirewallProfile -Enabled False\""
    }
  SETTINGS
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}