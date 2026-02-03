# Test: Hub Networking
# Validates address space allocation, subnet calculations, multi-hub addressing
# Note: Uses module overrides to mock external dependencies

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

override_module {
  target = module.azure_regions
  outputs = {
    regions_by_name = {
      uksouth = { geo_code = "uks", name = "uksouth", display_name = "UK South", zones = ["1", "2", "3"] }
      ukwest  = { geo_code = "ukw", name = "ukwest", display_name = "UK West", zones = ["1", "2", "3"] }
    }
  }
}

override_data {
  target = data.terraform_remote_state.management
  values = { outputs = {} }
}

# =============================================================================
# Single Hub - Address Space Allocation
# =============================================================================

run "single_hub_addressing" {
  command = plan

  assert {
    condition     = local.hub_addresses["uksouth"].hub_address_space == "10.0.0.0/16"
    error_message = "Default hub address space should be 10.0.0.0/16."
  }

  assert {
    condition     = local.hub_addresses["uksouth"].virtual_hub_prefix == "10.0.0.0/23"
    error_message = "Virtual Hub prefix should be 10.0.0.0/23."
  }

  assert {
    condition     = local.sidecar_subnets["uksouth"].sidecar_address_space == "10.0.4.0/22"
    error_message = "Sidecar address space should be 10.0.4.0/22 (second /22 block)."
  }
}

# =============================================================================
# Multi-Hub - Unique Addressing
# =============================================================================

run "multi_hub_addressing" {
  command = plan

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = true }
    }
  }

  assert {
    condition     = local.hub_addresses["uksouth"].hub_address_space != local.hub_addresses["ukwest"].hub_address_space
    error_message = "Hub address spaces must be unique per region."
  }

  assert {
    condition     = local.hub_indices["uksouth"] == 0 && local.hub_indices["ukwest"] == 1
    error_message = "Hub indices should be deterministic (alphabetical order)."
  }

  assert {
    condition     = local.primary_hub_region == "uksouth"
    error_message = "Primary hub should be first alphabetically."
  }
}

# =============================================================================
# Custom Address Space Override
# =============================================================================

run "custom_address_space" {
  command = plan

  variables {
    hubs = {
      uksouth = {
        enabled       = true
        address_space = "172.16.0.0/16"
      }
    }
  }

  assert {
    condition     = local.hub_addresses["uksouth"].hub_address_space == "172.16.0.0/16"
    error_message = "Hub address space should use custom override."
  }

  assert {
    condition     = startswith(local.hub_addresses["uksouth"].virtual_hub_prefix, "172.16.")
    error_message = "Virtual Hub prefix should be derived from custom address space."
  }
}

# =============================================================================
# Hub Index Consistency
# =============================================================================

run "hub_index_deterministic" {
  command = plan

  variables {
    hubs = {
      ukwest  = { enabled = true }
      uksouth = { enabled = true }
    }
  }

  # Index should be same regardless of declaration order
  assert {
    condition     = local.hub_indices["uksouth"] == 0
    error_message = "Hub index for uksouth should be 0 (alphabetically first)."
  }

  assert {
    condition     = local.hub_indices["ukwest"] == 1
    error_message = "Hub index for ukwest should be 1 (alphabetically second)."
  }
}
