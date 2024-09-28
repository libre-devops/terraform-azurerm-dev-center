output "dev_center_gallery_ids" {
  description = "The IDs of the Dev Center Galleries"
  value       = { for gallery in azurerm_dev_center_gallery.galleries : gallery.name => gallery.id }
}

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

output "dev_center_project" {
  description = "Details of the created Dev Center Project"
  value = {
    for key, project in azurerm_dev_center_project.projects :
    key => {
      id             = project.id
      name           = project.name
      dev_center_uri = project.dev_center_uri
      location       = project.location
      resource_group = project.resource_group_name
      max_dev_boxes  = project.maximum_dev_boxes_per_user
    }
  }
}

output "dev_center_tags" {
  description = "The tags of the Dev Centers"
  value       = { for dc in azurerm_dev_center.dev_centers : dc.name => dc.tags }
}

output "dev_center_uri" {
  description = "The URI of the Dev Centers"
  value       = { for dc in azurerm_dev_center.dev_centers : dc.name => dc.dev_center_uri }
}

output "gallery_id" {
  description = "The ID of the gallery"
  value       = { for k, v in azurerm_shared_image_gallery.compute_gallery : k => v.id }
}

output "gallery_location" {
  description = "The location name of the gallery"
  value       = { for k, v in azurerm_shared_image_gallery.compute_gallery : k => v.location }
}

output "gallery_name" {
  description = "The name of the gallery"
  value       = { for k, v in azurerm_shared_image_gallery.compute_gallery : k => v.name }
}

output "gallery_rg_name" {
  description = "The resource group name of the gallery"
  value       = { for k, v in azurerm_shared_image_gallery.compute_gallery : k => v.resource_group_name }
}

output "gallery_tags" {
  description = "The tags of the gallery"
  value       = { for k, v in azurerm_shared_image_gallery.compute_gallery : k => v.tags }
}

output "gallery_unique_name" {
  description = "The unique name of the gallery"
  value       = { for k, v in azurerm_shared_image_gallery.compute_gallery : k => v.unique_name }
}
