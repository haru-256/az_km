# 全リソースを格納するリソースグループ
resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Linux VM と Bastion を配置する仮想ネットワーク
resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

# Linux VM を配置するサブネット
resource "azurerm_subnet" "vm" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.vm_subnet_address_prefixes
}

# Azure Bastion を配置する専用サブネット（名前は AzureBastionSubnet が必須）
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.bastion_subnet_address_prefixes
}

# VM サブネットへの SSH を Bastion サブネットからのみ許可する NSG
resource "azurerm_network_security_group" "vm" {
  name                = "${var.name_prefix}-vm-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  # Bastion サブネットから VM サブネットへの SSH（TCP/22）接続を許可する。Bastion 経由でのみ VM に SSH できるよう制限するため、Bastion サブネットからのみ許可する必要がある。
  security_rule {
    name                       = "AllowSshFromBastionSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.bastion_subnet_address_prefixes[0]
    destination_address_prefix = "*"
  }
}

# Azure Bastion が動作するために必要な制御・データプレーン通信を許可する NSG
resource "azurerm_network_security_group" "bastion" {
  name                = "${var.name_prefix}-bastion-nsg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  # ユーザーが Azure portal やクライアントから、インターネット経由で Azure Bastion へ HTTPS（TCP/443）接続するために必要。Bastion はパブリックエンドポイントとして機能するため、このルールがないと管理接続ができない。
  security_rule {
    name                       = "AllowHttpsInboundFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Azure Gateway Manager サービスから Azure Bastion への HTTPS（TCP/443）制御プレーン接続を許可する。Bastion リソースのプロビジョニングやヘルス管理に必要であり、公式ドキュメントで必須とされている。
  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Azure Load Balancer から Azure Bastion への HTTPS（TCP/443）ヘルスプローブ接続を許可する。Bastion ホストの負荷分散と可用性維持のために必要。
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # 仮想ネットワーク内の Azure Bastion ホスト間で、データプレーン通信（TCP/8080, 5701）を許可する（Inbound）。冗長化やスケーリング時のホスト間連携に必要。
  security_rule {
    name                       = "AllowBastionHostCommunicationInbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Azure Bastion から同じ仮想ネットワーク内の VM へ SSH（TCP/22）/RDP（TCP/3389）接続を許可する。Bastion の主要な役割である VM への中継接続を成立させるために必要。
  security_rule {
    name                       = "AllowSshRdpOutboundToVirtualNetwork"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  # Azure Bastion から Azure クラウドサービス（AzureCloud）への HTTPS（TCP/443）接続を許可する。制御プレーン、テレメトリ、証明書などの通信に必要。
  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  # 仮想ネットワーク内の Azure Bastion ホスト間で、データプレーン通信（TCP/8080, 5701）を許可する（Outbound）。冗長構成のホスト間連携に必要。
  security_rule {
    name                       = "AllowBastionHostCommunicationOutbound"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Azure Bastion からインターネットへの HTTP（TCP/80）接続を許可する。セッション情報や診断ログの送信に必要。
  security_rule {
    name                       = "AllowSessionInformationOutbound"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# VM サブネットと NSG を関連付ける
resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# AzureBastionSubnet と NSG を関連付ける
resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

# Azure Bastion に割り当てる静的なパブリック IP
resource "azurerm_public_ip" "bastion" {
  name                = "${var.name_prefix}-bastion-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# パブリック IP 経由で SSH/RDP 接続を中継する Azure Bastion ホスト
resource "azurerm_bastion_host" "this" {
  name                = "${var.name_prefix}-bastion"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  depends_on = [azurerm_subnet_network_security_group_association.bastion]
}

# NAT Gateway に割り当てるアウトバウンド通信用の静的パブリック IP
resource "azurerm_public_ip" "nat" {
  name                = "${var.name_prefix}-nat-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Linux VM のアウトバウンドインターネット通信を提供する NAT Gateway
resource "azurerm_nat_gateway" "this" {
  name                    = "${var.name_prefix}-nat"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

# NAT Gateway とアウトバウンド用パブリック IP を関連付ける
resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# VM サブネットに NAT Gateway を関連付け、VM からの外向き通信を SNAT する
resource "azurerm_subnet_nat_gateway_association" "vm" {
  subnet_id      = azurerm_subnet.vm.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

# Linux VM がサブネットに接続するためのネットワークインターフェース
resource "azurerm_network_interface" "vm" {
  name                = "${var.name_prefix}-vm-nic"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

# パブリック IP を持たず、Bastion 経由で SSH する Linux VM
resource "azurerm_linux_virtual_machine" "this" {
  name                = "${var.name_prefix}-vm"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  # Standard_B1s のリタイアは 2028-09-30 まで猶予期間があるため、学習用途でそのまま使用
  # ref: https://jpaztech.github.io/blog/vm/2028-retire-vm/
  # tflint-ignore: azurerm_linux_virtual_machine_retired_size
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.vm.id]
  tags                  = var.tags

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  depends_on = [azurerm_subnet_network_security_group_association.vm]
}
