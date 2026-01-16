locals {
  environment_code = upper(coalesce(var.ensono_tags.environment, terraform.workspace))

  ensono_tags = var.ensono_tags.enabled ? {
    Application        = var.ensono_tags.application
    CreatedBy          = data.azurerm_client_config.current.object_id
    CustomerRef        = var.ensono_tags.customer_ref
    DeploymentDate     = var.ensono_tags.deployment_date != null ? var.ensono_tags.deployment_date : timestamp()
    Description        = "${local.environment_code} ${var.ensono_tags.description}"
    EnsonoSupportLevel = var.ensono_tags.ensono_support_level
    Environment        = local.environment_code
    Billing            = var.ensono_tags.billing
  } : {}

  ensono_tags_filtered = { for k, v in local.ensono_tags : k => v if v != null }
  tags                 = merge(var.tags, local.ensono_tags_filtered)
}
