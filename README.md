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
| [azurerm_dev_center_network_connection.network_connections](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_network_connection) | resource |
| [azurerm_dev_center_project.projects](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_center_project) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dev_centers"></a> [dev\_centers](#input\_dev\_centers) | List of Dev Centers to create, along with optional compute gallery configuration | <pre>list(object({<br/>    name          = string<br/>    location      = optional(string, "uksouth")<br/>    rg_name       = string<br/>    tags          = optional(map(string))<br/>    identity_type = optional(string)<br/>    identity_ids  = optional(list(string))<br/><br/>    # Network connection related fields<br/>    network_connection = optional(object({<br/>      name              = optional(string)<br/>      domain_join_type  = optional(string, "AzureADJoin")<br/>      subnet_id         = string<br/>      domain_name       = optional(string)<br/>      domain_password   = optional(string)<br/>      domain_username   = optional(string)<br/>      organization_unit = optional(string)<br/>      tags              = optional(map(string))<br/>    }))<br/><br/>    create_project = optional(bool, false) # Flag to create a Dev Center project<br/>    project = optional(object({<br/>      name                       = optional(string)<br/>      description                = optional(string)<br/>      maximum_dev_boxes_per_user = optional(number, 0)<br/>      tags                       = optional(map(string))<br/>    }))<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dev_center_identities"></a> [dev\_center\_identities](#output\_dev\_center\_identities) | The identities of the Dev Centers |
| <a name="output_dev_center_ids"></a> [dev\_center\_ids](#output\_dev\_center\_ids) | The IDs of the Dev Centers |
| <a name="output_dev_center_names"></a> [dev\_center\_names](#output\_dev\_center\_names) | The default name of the Dev Centers |
| <a name="output_dev_center_network_connection_ids"></a> [dev\_center\_network\_connection\_ids](#output\_dev\_center\_network\_connection\_ids) | The IDs of the Dev Center Network Connections |
| <a name="output_dev_center_project_id"></a> [dev\_center\_project\_id](#output\_dev\_center\_project\_id) | The ID of the created Dev Center Project |
| <a name="output_dev_center_project_location"></a> [dev\_center\_project\_location](#output\_dev\_center\_project\_location) | The location of the created Dev Center Project |
| <a name="output_dev_center_project_max_dev_boxes"></a> [dev\_center\_project\_max\_dev\_boxes](#output\_dev\_center\_project\_max\_dev\_boxes) | The maximum dev boxes per user for the created Dev Center Project |
| <a name="output_dev_center_project_name"></a> [dev\_center\_project\_name](#output\_dev\_center\_project\_name) | The name of the created Dev Center Project |
| <a name="output_dev_center_project_resource_group"></a> [dev\_center\_project\_resource\_group](#output\_dev\_center\_project\_resource\_group) | The resource group of the created Dev Center Project |
| <a name="output_dev_center_project_uri"></a> [dev\_center\_project\_uri](#output\_dev\_center\_project\_uri) | The URI of the created Dev Center Project |
| <a name="output_dev_center_tags"></a> [dev\_center\_tags](#output\_dev\_center\_tags) | The tags of the Dev Centers |
| <a name="output_dev_center_uri"></a> [dev\_center\_uri](#output\_dev\_center\_uri) | The URI of the Dev Centers |
