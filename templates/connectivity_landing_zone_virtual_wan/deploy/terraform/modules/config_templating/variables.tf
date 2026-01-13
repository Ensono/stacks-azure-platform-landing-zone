variable "starter_locations" {
  type        = list(string)
  description = "The default location for Azure resources (e.g 'uksouth')."
}

variable "starter_locations_short" {
  type        = map(string)
  default     = {}
  description = "Optional overrides for starter location short codes. Keys should match the built-in replacement names (for example 'starter_location_01_short', 'starter_location_02_short')."
}

variable "subscription_id_connectivity" {
  type        = string
  description = "Value of the subscription id for the connectivity subscription."
}

variable "custom_replacements" {
  type = object({
    names                      = optional(map(string), {})
    resource_group_identifiers = optional(map(string), {})
    resource_identifiers       = optional(map(string), {})
  })
  description = "Custom replacements."
}

variable "inputs" {
  type        = any
  description = "A map of input variables to be used in the configuration templating module."
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}
