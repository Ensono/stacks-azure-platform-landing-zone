# Test: Feature Toggle Behavior
# Validates that feature flags correctly enable/disable resources

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
  ensono_tags                  = { enabled = false }

  hubs = {
    uksouth = {
      enabled = true
      features = {
        firewall             = true
        bastion              = false
        vpn_gateway          = false
        expressroute_gateway = false
        private_dns_zones    = true
        private_dns_resolver = true
      }
    }
  }
}

run "feature_flags_propagate_to_hub_config" {
  command = plan

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.firewall == true
    error_message = "Firewall feature flag should propagate to hub config."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.bastion == false
    error_message = "Bastion feature flag should propagate to hub config."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.virtual_network_gateway_vpn == false
    error_message = "VPN gateway feature flag should propagate to hub config."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.private_dns_zones == true
    error_message = "Private DNS zones feature flag should propagate to hub config."
  }

  assert {
    condition     = local.hub_virtual_networks["uksouth"].enabled_resources.private_dns_resolver == true
    error_message = "Private DNS resolver feature flag should propagate to hub config."
  }
}

run "disabled_hub_is_excluded" {
  command = plan

  variables {
    hubs = {
      uksouth = { enabled = true }
      ukwest  = { enabled = false }
    }
  }

  assert {
    condition     = contains(keys(local.enabled_hubs), "uksouth")
    error_message = "Enabled hub should be in enabled_hubs."
  }

  assert {
    condition     = !contains(keys(local.enabled_hubs), "ukwest")
    error_message = "Disabled hub should not be in enabled_hubs."
  }
}
