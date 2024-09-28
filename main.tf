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

# Compute Gallery Resource
resource "azurerm_shared_image_gallery" "compute_gallery" {
  for_each = {
    for dc in var.dev_centers : dc.name => dc
    if lookup(dc, "create_compute_gallery", false) == true
  }

  name                = each.value.compute_gallery.name != null ? each.value.compute_gallery.name : "gal-${each.key}"
  resource_group_name = azurerm_dev_center.dev_centers[each.key].resource_group_name
  location            = azurerm_dev_center.dev_centers[each.key].location
  description         = try(each.value.compute_gallery.description, "Default compute gallery for ${each.key}")
  tags                = azurerm_dev_center.dev_centers[each.key].tags

  dynamic "sharing" {
    for_each = each.value.compute_gallery.sharing != null ? [each.value.compute_gallery.sharing] : []
    content {
      permission = title(sharing.value.permission)

      dynamic "community_gallery" {
        for_each = sharing.value.community_gallery != null ? [sharing.value.community_gallery] : []
        content {
          eula            = community_gallery.value.eula
          prefix          = community_gallery.value.prefix
          publisher_email = community_gallery.value.publisher_email
          publisher_uri   = community_gallery.value.publisher_uri
        }
      }
    }
  }
}

resource "azurerm_role_assignment" "contributor" {

  for_each = {
    for dc in var.dev_centers : dc.name => dc
    if lookup(dc, "create_compute_gallery", false) == true
  }
  principal_id         = azurerm_dev_center.dev_centers[each.key].identity[0].principal_id
  scope                = azurerm_dev_center.dev_centers[each.key].id
  role_definition_name = "Contributor"
}

# Dev Center Gallery Resource with Gallery ID from the Compute Gallery Resource
resource "azurerm_dev_center_gallery" "galleries" {
  depends_on = [azurerm_role_assignment.contributor]
  for_each = {
    for dc in var.dev_centers : dc.name => dc
    if lookup(dc, "create_compute_gallery", false) == true
  }

  dev_center_id     = azurerm_dev_center.dev_centers[each.key].id
  shared_gallery_id = azurerm_shared_image_gallery.compute_gallery[each.key].id # Reference the compute gallery's ID
  name              = each.value.compute_gallery.name
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

resource "azurerm_dev_center_catalog" "catalogs" {
  for_each = {
    for dc in var.dev_centers : dc.name => dc
    if lookup(dc, "create_catalog", false) == true
  }

  name                = each.value.catalog.name
  resource_group_name = azurerm_dev_center.dev_centers[each.key].resource_group_name
  dev_center_id       = azurerm_dev_center.dev_centers[each.key].id

  # GitHub catalog configuration
  dynamic "catalog_github" {
    for_each = lookup(each.value.catalog, "catalog_github", null) != null ? [each.value.catalog.catalog_github] : []
    content {
      branch            = catalog_github.value.branch
      path              = catalog_github.value.path
      key_vault_key_url = catalog_github.value.key_vault_key_url
      uri               = catalog_github.value.uri
    }
  }

  # Azure DevOps Git catalog configuration
  dynamic "catalog_adogit" {
    for_each = lookup(each.value.catalog, "catalog_adogit", null) != null ? [each.value.catalog.catalog_adogit] : []
    content {
      branch            = catalog_adogit.value.branch
      path              = catalog_adogit.value.path
      key_vault_key_url = catalog_adogit.value.key_vault_key_url
      uri               = catalog_adogit.value.uri
    }
  }
}
