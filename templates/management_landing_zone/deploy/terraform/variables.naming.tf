variable "company_name" {
  type        = string
  description = <<DESCRIPTION
The company name which is used in naming and tagging of resources.

This is truncated to the first 3 characters when used in resource names.
DESCRIPTION
}

variable "component_name" {
  type        = string
  default     = "man"
  description = <<DESCRIPTION
The name used in resource naming to identify the component. Must be 3 characters in length.

DESCRIPTION
  validation {
    condition     = length(var.component_name) == 3
    error_message = "component_name must be 3 characters."
  }
}

variable "naming_convention" {
  type        = string
  default     = "caf_azure"
  description = <<DESCRIPTION
The naming convention to use for generating resource names.

Supported values:
- "caf_azure"               - Cloud Adoption Framework for Azure. Uses the Azure/naming/azurerm module.
- "stacks_foundation_azure" - Stacks Foundation Azure module. Uses the Ensono/stacks-foundation-azure module.

DESCRIPTION
  validation {
    condition     = contains(["caf_azure", "stacks_foundation_azure"], var.naming_convention)
    error_message = "naming_convention must be 'caf_azure' or 'stacks_foundation_azure'."
  }
}
