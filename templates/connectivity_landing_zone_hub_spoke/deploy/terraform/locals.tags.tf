# =============================================================================
# Tag Configuration
# =============================================================================
#
# Builds the final tag set applied to all resources. Tags are merged in order:
#   1. var.tags (user-provided base tags)
#   2. ensono_tags (ensono-specific tags, if enabled)
#   3. hub.tags (hub-specific overrides, applied per-resource)
#
# Ensono tags take precedence over user tags to ensure compliance.
#
# =============================================================================

locals {
  # Ensono-specific tags (only when enabled)
  # DeploymentDate is auto-generated at apply time
  ensono_tags = var.ensono_tags.enabled ? {
    Application        = var.ensono_tags.application
    CreatedBy          = var.ensono_tags.created_by
    CustomerRef        = var.ensono_tags.customer_ref
    DeploymentDate     = var.ensono_tags.deployment_date != null ? var.ensono_tags.deployment_date : timestamp()
    Description        = var.ensono_tags.description
    EnsonoSupportLevel = var.ensono_tags.ensono_support_level
    Environment        = upper(coalesce(var.ensono_tags.environment, terraform.workspace))
    Billing            = var.ensono_tags.billing
  } : {}

  # Remove null values (e.g., if Billing is not set)
  ensono_tags_filtered = { for k, v in local.ensono_tags : k => v if v != null }

  # Final merged tags: user tags + ensono tags (ensono tags take precedence)
  tags = merge(var.tags, local.ensono_tags_filtered)
}
