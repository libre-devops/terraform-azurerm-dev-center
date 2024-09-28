```hcl
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
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_dev_center.dev_centers](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center) | resource |
| [azurerm_dev_center_catalog.catalogs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_catalog) | resource |
| [azurerm_dev_center_gallery.galleries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_gallery) | resource |
| [azurerm_dev_center_network_connection.network_connections](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_network_connection) | resource |
| [azurerm_dev_center_project.projects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_project) | resource |
| [azurerm_role_assignment.contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_shared_image_gallery.compute_gallery](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/shared_image_gallery) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dev_centers"></a> [dev\_centers](#input\_dev\_centers) | List of Dev Centers to create, along with optional compute gallery configuration | <pre>list(object({<br>    name          = string<br>    location      = optional(string, "uksouth")<br>    rg_name       = string<br>    tags          = optional(map(string))<br>    identity_type = optional(string)<br>    identity_ids  = optional(list(string))<br><br>    # Network connection related fields<br>    network_connection = optional(object({<br>      name              = optional(string)<br>      domain_join_type  = optional(string, "AzureADJoin")<br>      subnet_id         = string<br>      domain_name       = optional(string)<br>      domain_password   = optional(string)<br>      domain_username   = optional(string)<br>      organization_unit = optional(string)<br>      tags              = optional(map(string))<br>    }))<br><br>    # Flag to control compute gallery creation<br>    create_compute_gallery = optional(bool, false)<br><br>    # Compute gallery configuration<br>    compute_gallery = optional(object({<br>      name        = string<br>      description = optional(string, "The default compute gallery used within the Azure platform")<br>      sharing = optional(object({<br>        permission = optional(string, "Private")<br>        community_gallery = optional(object({<br>          eula            = string<br>          prefix          = string<br>          publisher_email = string<br>          publisher_uri   = string<br>        }))<br>      }))<br>    }))<br>    create_project = optional(bool, false) # Flag to create a Dev Center project<br>    project = optional(object({<br>      name                       = optional(string)<br>      description                = optional(string)<br>      maximum_dev_boxes_per_user = optional(number, 0)<br>      tags                       = optional(map(string))<br>    }))<br>    create_catalog = optional(bool, false) # Flag to create a catalog<br>    catalog = optional(object({<br>      name = string<br>      catalog_github = optional(object({<br>        branch            = string<br>        path              = string<br>        key_vault_key_url = string<br>        uri               = string<br>      }))<br>      catalog_adogit = optional(object({<br>        branch            = string<br>        path              = string<br>        key_vault_key_url = string<br>        uri               = string<br>      }))<br>    }))<br>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dev_center_gallery_ids"></a> [dev\_center\_gallery\_ids](#output\_dev\_center\_gallery\_ids) | The IDs of the Dev Center Galleries |
| <a name="output_dev_center_identities"></a> [dev\_center\_identities](#output\_dev\_center\_identities) | The identities of the Dev Centers |
| <a name="output_dev_center_ids"></a> [dev\_center\_ids](#output\_dev\_center\_ids) | The IDs of the Dev Centers |
| <a name="output_dev_center_names"></a> [dev\_center\_names](#output\_dev\_center\_names) | The default name of the Dev Centers |
| <a name="output_dev_center_network_connection_ids"></a> [dev\_center\_network\_connection\_ids](#output\_dev\_center\_network\_connection\_ids) | The IDs of the Dev Center Network Connections |
| <a name="output_dev_center_project"></a> [dev\_center\_project](#output\_dev\_center\_project) | Details of the created Dev Center Project |
| <a name="output_dev_center_tags"></a> [dev\_center\_tags](#output\_dev\_center\_tags) | The tags of the Dev Centers |
| <a name="output_dev_center_uri"></a> [dev\_center\_uri](#output\_dev\_center\_uri) | The URI of the Dev Centers |
| <a name="output_gallery_id"></a> [gallery\_id](#output\_gallery\_id) | The ID of the gallery |
| <a name="output_gallery_location"></a> [gallery\_location](#output\_gallery\_location) | The location name of the gallery |
| <a name="output_gallery_name"></a> [gallery\_name](#output\_gallery\_name) | The name of the gallery |
| <a name="output_gallery_rg_name"></a> [gallery\_rg\_name](#output\_gallery\_rg\_name) | The resource group name of the gallery |
| <a name="output_gallery_tags"></a> [gallery\_tags](#output\_gallery\_tags) | The tags of the gallery |
| <a name="output_gallery_unique_name"></a> [gallery\_unique\_name](#output\_gallery\_unique\_name) | The unique name of the gallery |
