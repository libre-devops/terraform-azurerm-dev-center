# Dev Center Resource
resource "azurerm_dev_center" "dev_centers" {
  for_each            = { for dc in var.dev_centers : dc.name => dc }
  location            = each.value.location
  name                = each.value.name
  resource_group_name = each.value.rg_name
  tags                = each.value.tags

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned" ? [each.value.identity_type] : []
    content {
      type = each.value.identity_type
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "SystemAssigned, UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = try(each.value.identity_ids, [])
    }
  }

  dynamic "identity" {
    for_each = each.value.identity_type == "UserAssigned" ? [each.value.identity_type] : []
    content {
      type         = each.value.identity_type
      identity_ids = length(try(each.value.identity_ids, [])) > 0 ? each.value.identity_ids : []
    }
  }
}

# Network Connection Resource
resource "azurerm_dev_center_network_connection" "network_connections" {
  for_each = { for dc in var.dev_centers : dc.name => dc if contains(keys(dc), "network_connection") && dc.network_connection != null }

  name                = each.value.network_connection.name != null ? each.value.network_connection.name : "netcon-${each.key}"
  resource_group_name = azurerm_dev_center.dev_centers[each.key].resource_group_name
  location            = azurerm_dev_center.dev_centers[each.key].location
  domain_join_type    = each.value.network_connection.domain_join_type
  subnet_id           = each.value.network_connection.subnet_id

  # Optional attributes
  domain_name       = try(each.value.network_connection.domain_name, null)
  domain_password   = try(each.value.network_connection.domain_password, null)
  domain_username   = try(each.value.network_connection.domain_username, null)
  organization_unit = try(each.value.network_connection.organization_unit, null)

  tags = azurerm_dev_center.dev_centers[each.key].tags
}


resource "azurerm_dev_center_project" "projects" {
  for_each = {
    for dc in var.dev_centers : dc.name => dc
    if lookup(dc, "create_project", false) == true
  }

  dev_center_id              = azurerm_dev_center.dev_centers[each.key].id
  location                   = azurerm_dev_center.dev_centers[each.key].location
  name                       = each.value.project.name != null ? each.value.project.name : "proj-${each.key}"
  resource_group_name        = azurerm_dev_center.dev_centers[each.key].resource_group_name
  description                = try(each.value.project.description, "Default project description for ${each.key}")
  maximum_dev_boxes_per_user = try(each.value.project.maximum_dev_boxes_per_user, null)
  tags                       = try(each.value.project.tags, azurerm_dev_center.dev_centers[each.key].tags)
}