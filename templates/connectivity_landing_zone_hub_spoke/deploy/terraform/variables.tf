variable "starter_locations" {
  type        = list(string)
  description = "The default location for Azure resources (e.g 'uksouth')."
  validation {
    condition     = length(var.starter_locations) > 0
    error_message = "You must provide at least one starter location region."
  }
  validation {
    condition     = length(var.hub_virtual_networks) <= length(var.starter_locations)
    error_message = "The number of hub virtual networks cannot exceed the number of starter locations."
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
  description = "Map of subscription IDs. Use 'connectivity' for hub network resources and 'management' for log analytics integration."
  nullable    = false
  validation {
    condition     = length(var.subscription_ids) == 0 || alltrue([for id in values(var.subscription_ids) : can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", id))])
    error_message = "All subscription IDs must be valid GUIDs."
  }
  validation {
    condition     = length(var.subscription_ids) == 0 || alltrue([for id in keys(var.subscription_ids) : contains(["connectivity", "management"], id)])
    error_message = "The keys of the subscription_ids map must be 'connectivity' or 'management'."
  }
}

variable "enable_avm_telemetry" {
  type        = bool
  default     = false
  description = "This variable controls whether or not telemetry is enabled for the module. For more information see <https://aka.ms/avm/telemetryinfo>. If it is set to false, then no telemetry will be collected."
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
