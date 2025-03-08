output "dev_center_identities" {
  description = "The identities of the Dev Centers"
  value = {
    for key, value in azurerm_dev_center.dev_centers : key =>
    length(value.identity) > 0 ? {
      type         = try(value.identity[0].type, null)
      principal_id = try(value.identity[0].principal_id, null)
      tenant_id    = try(value.identity[0].tenant_id, null)
      } : {
      type         = null
      principal_id = null
      tenant_id    = null
    }
  }
}

output "dev_center_ids" {
  description = "The IDs of the Dev Centers"
  value       = { for dc in azurerm_dev_center.dev_centers : dc.name => dc.id }
}

output "dev_center_names" {
  description = "The default name of the Dev Centers"
  value       = { for dc in azurerm_dev_center.dev_centers : dc.name => dc.name }
}

output "dev_center_network_connection_ids" {
  description = "The IDs of the Dev Center Network Connections"
  value = {
    for dc in azurerm_dev_center_network_connection.network_connections : dc.name => dc.id
  }
}

output "dev_center_project_id" {
  description = "The ID of the created Dev Center Project"
  value       = { for key, project in azurerm_dev_center_project.projects : key => project.id }
}

output "dev_center_project_location" {
  description = "The location of the created Dev Center Project"
  value       = { for key, project in azurerm_dev_center_project.projects : key => project.location }
}

output "dev_center_project_max_dev_boxes" {
  description = "The maximum dev boxes per user for the created Dev Center Project"
  value       = { for key, project in azurerm_dev_center_project.projects : key => project.maximum_dev_boxes_per_user }
}

output "dev_center_project_name" {
  description = "The name of the created Dev Center Project"
  value       = { for key, project in azurerm_dev_center_project.projects : key => project.name }
}

output "dev_center_project_resource_group" {
  description = "The resource group of the created Dev Center Project"
  value       = { for key, project in azurerm_dev_center_project.projects : key => project.resource_group_name }
}

output "dev_center_project_uri" {
  description = "The URI of the created Dev Center Project"
  value       = { for key, project in azurerm_dev_center_project.projects : key => project.dev_center_uri }
}

output "dev_center_tags" {
  description = "The tags of the Dev Centers"
  value       = { for dc in azurerm_dev_center.dev_centers : dc.name => dc.tags }
}

output "dev_center_uri" {
  description = "The URI of the Dev Centers"
  value       = { for dc in azurerm_dev_center.dev_centers : dc.name => dc.dev_center_uri }
}
