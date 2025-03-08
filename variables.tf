variable "dev_centers" {
  description = "List of Dev Centers to create, along with optional compute gallery configuration"
  type = list(object({
    name          = string
    location      = optional(string, "uksouth")
    rg_name       = string
    tags          = optional(map(string))
    identity_type = optional(string)
    identity_ids  = optional(list(string))

    # Network connection related fields
    network_connection = optional(object({
      name              = optional(string)
      domain_join_type  = optional(string, "AzureADJoin")
      subnet_id         = string
      domain_name       = optional(string)
      domain_password   = optional(string)
      domain_username   = optional(string)
      organization_unit = optional(string)
      tags              = optional(map(string))
    }))

    create_project = optional(bool, false) # Flag to create a Dev Center project
    project = optional(object({
      name                       = optional(string)
      description                = optional(string)
      maximum_dev_boxes_per_user = optional(number, 0)
      tags                       = optional(map(string))
    }))
  }))
}
