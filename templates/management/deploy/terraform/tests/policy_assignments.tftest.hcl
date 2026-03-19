# Test: Policy Assignments
# Validates Defender plan toggles and policy default value computation

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
# Defender Plans - Default (All Disabled)
# =============================================================================

run "defender_plans_all_disabled_by_default" {
  command   = plan
  state_key = "defender_defaults"

  variables {
    microsoft_defender_settings = {
      email_security_contact = "test@example.invalid"
    }
  }

  # Spot-check representative plans map to "Disabled"
  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForServers).value == "Disabled"
    error_message = "Servers plan should be Disabled by default."
  }

  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForStorage).value == "Disabled"
    error_message = "Storage plan should be Disabled by default."
  }

  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForCspm).value == "Disabled"
    error_message = "CSPM plan should be Disabled by default."
  }

  # Sub-features should be "false" by default
  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.ascForStorageIsOnUploadMalwareScanningEnabled).value == "false"
    error_message = "Malware scanning sub-feature should be 'false' by default."
  }
}

# =============================================================================
# Defender Plans - Selective Enable
# =============================================================================

run "defender_plans_selective_enable" {
  command   = plan
  state_key = "defender_enabled"

  variables {
    microsoft_defender_settings = {
      email_security_contact = "security@example.invalid"
      defender_plans = {
        servers = true
        storage = true
        cspm    = true
      }
      subfeatures = {
        storage_on_upload_malware_scanning = true
        cspm_agentless_vm_scanning         = true
      }
    }
  }

  # Enabled plans should be "DeployIfNotExists"
  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForServers).value == "DeployIfNotExists"
    error_message = "Servers plan should be DeployIfNotExists when enabled."
  }

  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForStorage).value == "DeployIfNotExists"
    error_message = "Storage plan should be DeployIfNotExists when enabled."
  }

  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForCspm).value == "DeployIfNotExists"
    error_message = "CSPM plan should be DeployIfNotExists when enabled."
  }

  # Non-enabled plans should still be "Disabled"
  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.enableAscForKeyVault).value == "Disabled"
    error_message = "Key Vault plan should remain Disabled when not explicitly enabled."
  }

  # Enabled sub-features should be "true"
  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.ascForStorageIsOnUploadMalwareScanningEnabled).value == "true"
    error_message = "Malware scanning should be 'true' when enabled."
  }

  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.ascForCspmIsAgentlessVmScanningEnabled).value == "true"
    error_message = "CSPM agentless VM scanning should be 'true' when enabled."
  }
}

# =============================================================================
# Defender Settings - Email and Export RG Propagation
# =============================================================================

run "defender_settings_propagated" {
  command   = plan
  state_key = "defender_settings"

  variables {
    microsoft_defender_settings = {
      email_security_contact     = "soc@example.invalid"
      export_resource_group_name = "rg-custom-export"
    }
  }

  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.emailSecurityContact).value == "soc@example.invalid"
    error_message = "Email security contact should be propagated to policy parameters."
  }

  assert {
    condition     = jsondecode(local.default_policy_assignments_to_modify.alz.policy_assignments["Deploy-MDFC-Config-H224"].parameters.ascExportResourceGroupName).value == "rg-custom-export"
    error_message = "Export resource group name should be propagated to policy parameters."
  }
}

# =============================================================================
# Policy Default Values - Empty When Resources Disabled
# =============================================================================

run "policy_values_empty_when_resources_disabled" {
  command   = plan
  state_key = "policy_disabled"

  assert {
    condition     = length(local.policy_values_from_resources) == 0
    error_message = "policy_values_from_resources should be empty when management_resources_enabled is false."
  }
}

# =============================================================================
# Private DNS Zones - DoNotEnforce by Default
# =============================================================================

run "private_dns_zones_not_enforced" {
  command   = plan
  state_key = "dns_enforce"

  assert {
    condition     = local.default_policy_assignments_to_modify.corp.policy_assignments["Deploy-Private-DNS-Zones"].enforcement_mode == "DoNotEnforce"
    error_message = "Private DNS Zones should default to DoNotEnforce."
  }
}
