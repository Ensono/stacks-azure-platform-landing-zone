variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources. Merged with ensono_tags (if enabled) and hub-specific tags."
}

variable "ensono_tags" {
  type = object({
    enabled = optional(bool, false)

    # Required when enabled
    application          = optional(string, "Connectivity Platform Landing Zone")
    customer_ref         = optional(string)
    deployment_date      = optional(string)
    description          = optional(string, "Connectivity Platform Landing Zone")
    ensono_support_level = optional(string)
    environment          = optional(string)
    billing              = optional(string)
  })

  default = {
    enabled = false
  }

  description = "Ensono-specific tags for CMDB and billing integration. Set enabled = true and provide required fields. CreatedBy is automatically set to the deploying identity."

  validation {
    condition = (
      !var.ensono_tags.enabled ||
      (var.ensono_tags.application != null && var.ensono_tags.application != "")
    )
    error_message = "When ensono_tags.enabled is true, 'application' is required."
  }

  validation {
    condition = (
      !var.ensono_tags.enabled ||
      (var.ensono_tags.customer_ref != null && var.ensono_tags.customer_ref != "")
    )
    error_message = "When ensono_tags.enabled is true, 'customer_ref' is required."
  }

  validation {
    condition = (
      !var.ensono_tags.enabled ||
      (var.ensono_tags.description != null && var.ensono_tags.description != "")
    )
    error_message = "When ensono_tags.enabled is true, 'description' is required."
  }

  validation {
    condition = (
      !var.ensono_tags.enabled ||
      (var.ensono_tags.ensono_support_level != null &&
      contains(["Fully-Managed", "Self-Managed", "Co-Managed", "Unmanaged"], var.ensono_tags.ensono_support_level))
    )
    error_message = "When ensono_tags.enabled is true, 'ensono_support_level' is required and must be one of: Fully-Managed, Self-Managed, Co-Managed, Unmanaged."
  }

  validation {
    condition = (
      !var.ensono_tags.enabled ||
      var.ensono_tags.environment == null ||
      can(regex("^[A-Za-z]{3}$", var.ensono_tags.environment))
    )
    error_message = "When ensono_tags.enabled is true, 'environment' must be a 3-character code (e.g., PRD, QA, TST, DEV) or null to use terraform.workspace."
  }
}
