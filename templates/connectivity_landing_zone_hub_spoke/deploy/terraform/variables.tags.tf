# =============================================================================
# Tag Variables
# =============================================================================
#
# Configuration for resource tagging. Tags are merged in order:
#   1. var.tags (user-provided base tags)
#   2. ensono_tags (organization-specific tags, if enabled)
#   3. hub.tags (hub-specific overrides, applied per-resource)
#
# See locals.tags.tf for the merged output (local.tags).
#
# =============================================================================

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources. Merged with ensono_tags (if enabled) and hub-specific tags."
}

# -----------------------------------------------------------------------------
# Ensono-Specific Tags
# -----------------------------------------------------------------------------
# Optional ensono-specific tags for CMDB integration and billing. Set `enabled`
# to true and provide required values. Tags are automatically merged with
# var.tags when enabled.
#
variable "ensono_tags" {
  type = object({
    enabled = optional(bool, false)

    # Required when enabled
    application          = optional(string)
    created_by           = optional(string)
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

  description = "Ensono-specific tags for CMDB and billing integration. Set enabled = true and provide required fields."

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
      (var.ensono_tags.created_by != null && can(regex("^[^@]+@[^@]+\\.[^@]+$", var.ensono_tags.created_by)))
    )
    error_message = "When ensono_tags.enabled is true, 'created_by' must be a valid email address."
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
      contains(["Fully-Managed", "Self-Managed", "Co-Managed", "Unmanaged"], coalesce(var.ensono_tags.ensono_support_level, ""))
    )
    error_message = "When ensono_tags.enabled is true, 'ensono_support_level' must be one of: Fully-Managed, Self-Managed, Co-Managed, Unmanaged."
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
