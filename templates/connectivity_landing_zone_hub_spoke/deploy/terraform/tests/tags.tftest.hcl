# Test: Tag Generation
# Validates ensono_tags behavior and filtering

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

variables {
  connectivity_subscription_id = "00000000-0000-0000-0000-000000000000"
  hub_network_address_prefix   = "10.0.0.0/8"
  hubs                         = { uksouth = { enabled = true } }
}

run "ensono_tags_disabled_produces_empty_map" {
  command = plan

  variables {
    ensono_tags = { enabled = false }
  }

  assert {
    condition     = length(local.ensono_tags) == 0
    error_message = "Ensono tags should be empty when disabled."
  }
}

run "ensono_tags_enabled_and_merged_correctly" {
  command = plan

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
    condition     = local.ensono_tags["Application"] == "Test Application"
    error_message = "Application tag should match input."
  }

  assert {
    condition     = local.ensono_tags["CustomerRef"] == "TEST-001"
    error_message = "CustomerRef tag should match input."
  }

  assert {
    condition     = local.ensono_tags["EnsonoSupportLevel"] == "Self-Managed"
    error_message = "EnsonoSupportLevel tag should match input."
  }

  assert {
    condition     = local.ensono_tags["Description"] != null
    error_message = "Description tag should have default value."
  }

  assert {
    condition     = local.ensono_tags["CreatedBy"] != null
    error_message = "CreatedBy tag should be auto-populated."
  }

  assert {
    condition     = local.ensono_tags["Environment"] == upper(terraform.workspace)
    error_message = "Environment should default to uppercase terraform workspace."
  }

  assert {
    condition     = local.tags["CustomTag"] == "CustomValue"
    error_message = "Custom tags should be included in merged tags."
  }

  assert {
    condition     = local.tags["Application"] == "Test Application"
    error_message = "Ensono tags should be included in merged tags."
  }
}
