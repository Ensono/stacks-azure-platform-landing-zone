# Test: Subscription Placement
# Validates subscription placement logic for management groups

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

mock_provider "alz" {}

# Override AVM modules that depend on azure/modtm provider
override_module {
  target = module.azure_regions
  outputs = {
    regions_by_name = {
      uksouth = {
        name         = "uksouth"
        display_name = "UK South"
        geo_code     = "uks"
      }
    }
    regions                             = {}
    regions_by_display_name             = {}
    regions_by_geography                = {}
    regions_by_geography_group          = {}
    regions_by_name_or_display_name     = {}
    valid_region_display_names          = []
    valid_region_names                  = ["uksouth"]
    valid_region_names_or_display_names = []
  }
}

override_module {
  target = module.resource_groups
}

test {
  parallel = true
}

# =============================================================================
# Subscription Placement - All Subscriptions Provided
# =============================================================================

run "all_subscriptions_placed" {
  command   = plan
  state_key = "all_subs"

  variables {
    connectivity_subscription_id = "11111111-1111-1111-1111-111111111111"
    identity_subscription_id     = "22222222-2222-2222-2222-222222222222"
    security_subscription_id     = "33333333-3333-3333-3333-333333333333"
  }

  assert {
    condition     = local.subscription_placement["connectivity"].management_group_name == "connectivity"
    error_message = "Connectivity subscription should be placed in 'connectivity' management group."
  }

  assert {
    condition     = local.subscription_placement["identity"].management_group_name == "identity"
    error_message = "Identity subscription should be placed in 'identity' management group."
  }

  assert {
    condition     = local.subscription_placement["management"].management_group_name == "management"
    error_message = "Management subscription should be placed in 'management' management group."
  }

  assert {
    condition     = local.subscription_placement["security"].management_group_name == "security"
    error_message = "Security subscription should be placed in 'security' management group."
  }

  assert {
    condition     = length(local.subscription_placement) == 4
    error_message = "All four subscriptions should be placed."
  }
}

# =============================================================================
# Subscription Placement - Skip Mode (Single Subscription)
# =============================================================================

run "skip_placement_only_management" {
  command   = plan
  state_key = "skip_placement"

  variables {
    connectivity_subscription_id = "11111111-1111-1111-1111-111111111111"
    identity_subscription_id     = "22222222-2222-2222-2222-222222222222"
    skip_subscription_placement  = true
  }

  assert {
    condition     = length(local.subscription_placement) == 1
    error_message = "Only management subscription should be placed when skip_subscription_placement = true."
  }

  assert {
    condition     = local.subscription_placement["management"].management_group_name == "management"
    error_message = "Management subscription should be placed in 'management' management group."
  }
}

# =============================================================================
# Subscription Placement - Optional Security Subscription
# =============================================================================

run "security_subscription_omitted_by_default" {
  command   = plan
  state_key = "no_security"

  variables {
    connectivity_subscription_id = "11111111-1111-1111-1111-111111111111"
    identity_subscription_id     = "22222222-2222-2222-2222-222222222222"
  }

  assert {
    condition     = !contains(keys(local.subscription_placement), "security")
    error_message = "Security subscription should not be placed when security_subscription_id is null."
  }

  assert {
    condition     = length(local.subscription_placement) == 3
    error_message = "Three subscriptions should be placed when security is omitted."
  }
}
