# Test: Naming and Tags
# Validates CAF naming conventions and tag generation

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      client_id       = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      object_id       = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azapi" {
  mock_data "azapi_resource_action" {
    defaults = {
      output = {
        value = [
          { name = "uksouth", displayName = "UK South", metadata = { regionType = "Physical", regionCategory = "Recommended", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "London", pairedRegion = [{ name = "ukwest" }] } },
          { name = "ukwest", displayName = "UK West", metadata = { regionType = "Physical", regionCategory = "Other", geography = "United Kingdom", geographyGroup = "Europe", physicalLocation = "Cardiff", pairedRegion = [{ name = "uksouth" }] } }
        ]
      }
    }
  }
}

mock_provider "random" {}

mock_provider "local" {}

mock_provider "modtm" {}

# Variables loaded from terraform.tfvars

test {
  parallel = true
}

# =============================================================================
# CAF Naming Conventions and Default Tags
# =============================================================================

run "naming_and_tags_defaults" {
  command   = plan
  state_key = "defaults"

  # CAF naming prefixes
  assert {
    condition     = startswith(local.hub_names["uksouth"].resource_group, "rg-") && can(regex("rg-ens-", local.hub_names["uksouth"].resource_group))
    error_message = "Resource group name should follow CAF naming with company name."
  }

  assert {
    condition     = startswith(local.hub_names["uksouth"].virtual_network, "vnet-") && startswith(local.hub_names["uksouth"].firewall, "afw-") && startswith(local.hub_names["uksouth"].bastion, "bas-") && startswith(local.hub_names["uksouth"].route_table_firewall, "route-")
    error_message = "All resource names should follow CAF naming conventions."
  }

  # Ensono tags disabled by default
  assert {
    condition     = length(local.ensono_tags) == 0
    error_message = "Ensono tags should be empty when disabled."
  }

  # Variable validation
  assert {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.connectivity_subscription_id)) && can(cidrhost(var.hub_network_address_prefix, 0)) && length(var.hubs) <= 10
    error_message = "Variables must pass validation rules."
  }
}

# =============================================================================
# Ensono Tags Enabled
# =============================================================================

run "ensono_tags_enabled" {
  command   = plan
  state_key = "tags"

  variables {
    tags = { CustomTag = "CustomValue" }
    ensono_tags = {
      enabled              = true
      application          = "Test Application"
      customer_ref         = "TEST-001"
      ensono_support_level = "Self-Managed"
    }
  }

  assert {
    condition     = local.ensono_tags["Application"] == "Test Application" && local.ensono_tags["CustomerRef"] == "TEST-001"
    error_message = "Ensono tags should match input values."
  }

  assert {
    condition     = local.tags["CustomTag"] == "CustomValue" && local.tags["Application"] == "Test Application"
    error_message = "Custom and Ensono tags should be merged."
  }
}
