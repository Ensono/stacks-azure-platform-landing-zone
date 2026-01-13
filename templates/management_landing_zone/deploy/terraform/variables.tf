variable "starter_locations" {
  type        = list(string)
  description = "The default location for Azure resources (e.g 'uksouth')."
  validation {
    condition     = length(var.starter_locations) > 0
    error_message = "You must provide at least one starter location region."
  }
}

variable "starter_locations_short" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Optional overrides for the starter location short codes.

Keys should match the built-in replacement names used in the examples, for example:
- starter_location_01_short
- starter_location_02_short

If not provided, short codes are derived from the regions module using geo_code when available, falling back to short_name when no geo_code is published.
DESCRIPTION
}

variable "subscription_ids" {
  type        = map(string)
  default     = {}
  description = "The list of subscription IDs to deploy the Platform Landing Zone into."
  nullable    = false
  validation {
    condition     = length(var.subscription_ids) == 0 || alltrue([for id in values(var.subscription_ids) : can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", id))])
    error_message = "All subscription IDs must be valid GUIDs."
  }
  validation {
    condition     = length(var.subscription_ids) == 0 || alltrue([for id in keys(var.subscription_ids) : contains(["management", "connectivity", "identity", "security"], id)])
    error_message = "The keys of the subscription_ids map must be one of 'management', 'connectivity', 'identity' or 'security'."
  }
}

variable "root_parent_management_group_id" {
  type        = string
  default     = ""
  description = "The ID of the management group that the ALZ hierarchy will be nested under. Will default to the Tenant Root Group."
}

variable "custom_replacements" {
  type = object({
    names                      = optional(map(string), {})
    resource_group_identifiers = optional(map(string), {})
    resource_identifiers       = optional(map(string), {})
  })
  default = {
    names                      = {}
    resource_group_identifiers = {}
    resource_identifiers       = {}
  }
  description = "Custom replacements."
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags to add to all resources managed by this module."
}
