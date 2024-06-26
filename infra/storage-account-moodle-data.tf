resource "random_string" "storage-account-moodle-data" {
  length           = 6
  special          = false
  upper            = false
}

resource "azurerm_storage_account" "moodle-data" {
  name                     = "moodledata${random_string.storage-account-moodle-data.result}"
  resource_group_name      = data.azurerm_resource_group.moodle-high-scale.name
  location                 = data.azurerm_resource_group.moodle-high-scale.location
  account_kind             = "FileStorage"
  account_tier             = "Premium"
  account_replication_type = "LRS"
  # disable secure transfer
  enable_https_traffic_only = false

}

resource "azurerm_storage_share" "moodle-data" {
  name                  = "moodle-data"
  storage_account_name  = azurerm_storage_account.moodle-data.name
  quota                 = 100
  enabled_protocol      = "NFS"
}

resource "azurerm_private_endpoint" "moodle-data" {
  name                = "moodle-data"
  location            = data.azurerm_resource_group.moodle-high-scale.location
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
  subnet_id           = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "data.azurerm_resource_group.moodle-high-scale.location"
    private_connection_resource_id = azurerm_storage_account.moodle-data.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "nfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage-nfs.id]
  }
}

resource "azurerm_private_dns_zone" "storage-nfs" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = data.azurerm_resource_group.moodle-high-scale.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage-nfs" {
  name                  = "storage-nfs"
  resource_group_name   = data.azurerm_resource_group.moodle-high-scale.name
  private_dns_zone_name = azurerm_private_dns_zone.storage-nfs.name
  virtual_network_id    = azurerm_virtual_network.moodle-high-scale.id
}