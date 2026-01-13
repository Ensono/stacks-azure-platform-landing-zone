/*
--- Built-in Replacements ---
This file contains built-in replacements to avoid repeating the same hard-coded values.
Replacements are denoted by the dollar-dollar curly braces token (e.g. $${starter_location_01}). The following details each built-in replacements that you can use:
`starter_location_01`: This the primary an Azure location sourced from the `starter_locations` variable. This can be used to set the location of resources.
`starter_location_02` to `starter_location_##`: These are the secondary Azure locations sourced from the `starter_locations` variable. This can be used to set the location of resources.
`starter_location_01_short`: Short code for the primary Azure location. Defaults to the region geo_code, or short_name if no geo_code is available. Can be overridden via the starter_locations_short variable.
`starter_location_02_short` to `starter_location_##_short`: Short codes for the secondary Azure locations. Same behavior and override rules as starter_location_01_short.
`subscription_id_connectivity`: The subscription ID of the subscription to deploy the connectivity resources to, sourced from the variable `subscription_ids`.
*/

/*
--- Starter Locations ---
You can define the Azure regions to use throughout the configuration.
The first location will be used as the primary location, the second as the secondary location, and so on.
*/
starter_locations = ["<region-1>", "<region-2>"]

/*
--- Custom Replacements ---
You can define custom replacements to use throughout the configuration.
*/
custom_replacements = {
  /*
  --- Custom Name Replacements ---
  You can define custom names and other strings to use throughout the configuration.
  You can only use the built in replacements in this section.
  NOTE: You cannot refer to another custom name in this variable.
  */
  names = {
    # Resource group names
    connectivity_hub_vwan_resource_group_name      = "rg-hub-vwan-$${starter_location_01_short}"
    connectivity_hub_primary_resource_group_name   = "rg-hub-$${starter_location_01_short}"
    connectivity_hub_secondary_resource_group_name = "rg-hub-$${starter_location_02_short}"
    dns_resource_group_name                        = "rg-hub-dns-$${starter_location_01_short}"
    ddos_resource_group_name                       = "rg-hub-ddos-$${starter_location_01_short}"

    # Resource names
    ddos_protection_plan_name = "ddos-$${starter_location_01_short}"

    # Resource provisioning global connectivity
    ddos_protection_plan_enabled = false

    # Resource provisioning primary connectivity
    primary_firewall_enabled                              = true
    primary_virtual_network_gateway_express_route_enabled = false
    primary_virtual_network_gateway_vpn_enabled           = false
    primary_private_dns_zones_enabled                     = true
    primary_private_dns_auto_registration_zone_enabled    = true
    primary_private_dns_resolver_enabled                  = true
    primary_bastion_enabled                               = false
    primary_sidecar_virtual_network_enabled               = true

    # Resource provisioning secondary connectivity
    secondary_firewall_enabled                              = true
    secondary_virtual_network_gateway_express_route_enabled = false
    secondary_virtual_network_gateway_vpn_enabled           = false
    secondary_private_dns_zones_enabled                     = true
    secondary_private_dns_auto_registration_zone_enabled    = true
    secondary_private_dns_resolver_enabled                  = true
    secondary_bastion_enabled                               = false
    secondary_sidecar_virtual_network_enabled               = true

    # Resource names primary connectivity
    primary_hub_name                                   = "vwan-hub-$${starter_location_01_short}"
    primary_sidecar_virtual_network_name               = "vnet-sidecar-$${starter_location_01_short}"
    primary_firewall_name                              = "fw-hub-$${starter_location_01_short}"
    primary_firewall_policy_name                       = "fwp-hub-$${starter_location_01_short}"
    primary_virtual_network_gateway_express_route_name = "vgw-hub-er-$${starter_location_01_short}"
    primary_virtual_network_gateway_vpn_name           = "vgw-hub-vpn-$${starter_location_01_short}"
    primary_private_dns_resolver_name                  = "pdr-hub-dns-$${starter_location_01_short}"
    primary_bastion_host_name                          = "bas-hub-$${starter_location_01_short}"
    primary_bastion_host_public_ip_name                = "pip-bastion-hub-$${starter_location_01_short}"

    # Resource names secondary connectivity
    secondary_hub_name                                   = "vwan-hub-$${starter_location_02_short}"
    secondary_sidecar_virtual_network_name               = "vnet-sidecar-$${starter_location_02_short}"
    secondary_firewall_name                              = "fw-hub-$${starter_location_02_short}"
    secondary_firewall_policy_name                       = "fwp-hub-$${starter_location_02_short}"
    secondary_virtual_network_gateway_express_route_name = "vgw-hub-er-$${starter_location_02_short}"
    secondary_virtual_network_gateway_vpn_name           = "vgw-hub-vpn-$${starter_location_02_short}"
    secondary_private_dns_resolver_name                  = "pdr-hub-dns-$${starter_location_02_short}"
    secondary_bastion_host_name                          = "bas-hub-$${starter_location_02_short}"
    secondary_bastion_host_public_ip_name                = "pip-bastion-hub-$${starter_location_02_short}"

    # Private DNS Zones primary
    primary_auto_registration_zone_name = "$${starter_location_01}.azure.local"

    # Private DNS Zones secondary
    secondary_auto_registration_zone_name = "$${starter_location_02}.azure.local"

    # IP Ranges Primary
    # Regional Address Space: 10.0.0.0/16
    primary_hub_address_space                          = "10.0.0.0/22"
    primary_sidecar_virtual_network_address_space      = "10.0.4.0/22"
    primary_bastion_subnet_address_prefix              = "10.0.4.0/26"
    primary_private_dns_resolver_subnet_address_prefix = "10.0.4.64/28"

    # IP Ranges Secondary
    # Regional Address Space: 10.1.0.0/16
    secondary_hub_address_space                          = "10.1.0.0/22"
    secondary_sidecar_virtual_network_address_space      = "10.1.4.0/22"
    secondary_bastion_subnet_address_prefix              = "10.1.4.0/26"
    secondary_private_dns_resolver_subnet_address_prefix = "10.1.4.64/28"
  }

  /*
  --- Custom Resource Group Identifier Replacements ---
  You can define custom resource group identifiers to use throughout the configuration.
  You can only use the templated variables and custom names in this section.
  NOTE: You cannot refer to another custom resource group identifier in this variable.
  */
  resource_group_identifiers = {
    ddos_protection_plan_resource_group_id   = "/subscriptions/$${subscription_id_connectivity}/resourcegroups/$${ddos_resource_group_name}"
    primary_connectivity_resource_group_id   = "/subscriptions/$${subscription_id_connectivity}/resourceGroups/$${connectivity_hub_primary_resource_group_name}"
    secondary_connectivity_resource_group_id = "/subscriptions/$${subscription_id_connectivity}/resourceGroups/$${connectivity_hub_secondary_resource_group_name}"
    dns_resource_group_id                    = "/subscriptions/$${subscription_id_connectivity}/resourceGroups/$${dns_resource_group_name}"
  }

  /*
  --- Custom Resource Identifier Replacements ---
  You can define custom resource identifiers to use throughout the configuration.
  You can only use the templated variables, custom names and customer resource group identifiers in this variable.
  NOTE: You cannot refer to another custom resource identifier in this variable.
  */
  resource_identifiers = {
    ddos_protection_plan_id = "$${ddos_protection_plan_resource_group_id}/providers/Microsoft.Network/ddosProtectionPlans/$${ddos_protection_plan_name}"
  }
}

/*
--- Tags ---
This variable can be used to apply tags to all resources that support it. Some resources allow overriding these tags.
*/
tags = {
  deployed_by = "Terraform"
  source      = "Stacks Azure Platform Landing Zone Connectivity Module"
}

/*
--- Connectivity - Virtual WAN ---
You can use this section to customize the virtual wan networking that will be deployed.
*/
connectivity_resource_groups = {
  ddos = {
    name     = "$${ddos_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = "$${ddos_protection_plan_enabled}"
    }
  }
  vwan = {
    name     = "$${connectivity_hub_vwan_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = true
    }
  }
  vwan_hub_primary = {
    name     = "$${connectivity_hub_primary_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = true
    }
  }
  vwan_hub_secondary = {
    name     = "$${connectivity_hub_secondary_resource_group_name}"
    location = "$${starter_location_02}"
    settings = {
      enabled = true
    }
  }
  dns = {
    name     = "$${dns_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = "$${primary_private_dns_zones_enabled}"
    }
  }
}

virtual_wan_settings = {
  enabled_resources = {
    ddos_protection_plan = "$${ddos_protection_plan_enabled}"
  }
  virtual_wan = {
    name                = "vwan-$${starter_location_01_short}"
    resource_group_name = "$${connectivity_hub_vwan_resource_group_name}"
    location            = "$${starter_location_01}"
  }
  ddos_protection_plan = {
    name                = "$${ddos_protection_plan_name}"
    resource_group_name = "$${ddos_resource_group_name}"
    location            = "$${starter_location_01}"
  }
}

virtual_hubs = {
  primary = {
    location = "$${starter_location_01}"
    /*
      NOTE: We are defaulting to a separate resource group for the hub per best practice for resiliency
      If you prefer to use the same resource group as the vwan, then set this to `$${connectivity_hub_vwan_resource_group_name}`
    */
    default_parent_id = "$${primary_connectivity_resource_group_id}"
    enabled_resources = {
      firewall                              = "$${primary_firewall_enabled}"
      bastion                               = "$${primary_bastion_enabled}"
      virtual_network_gateway_express_route = "$${primary_virtual_network_gateway_express_route_enabled}"
      virtual_network_gateway_vpn           = "$${primary_virtual_network_gateway_vpn_enabled}"
      private_dns_zones                     = "$${primary_private_dns_zones_enabled}"
      private_dns_resolver                  = "$${primary_private_dns_resolver_enabled}"
      sidecar_virtual_network               = "$${primary_sidecar_virtual_network_enabled}"
    }
    hub = {
      name           = "$${primary_hub_name}"
      address_prefix = "$${primary_hub_address_space}"
    }
    firewall = {
      name = "$${primary_firewall_name}"
    }
    firewall_policy = {
      name = "$${primary_firewall_policy_name}"
    }
    virtual_network_gateways = {
      express_route = {
        name = "$${primary_virtual_network_gateway_express_route_name}"
      }
      vpn = {
        name = "$${primary_virtual_network_gateway_vpn_name}"
      }
    }
    private_dns_zones = {
      parent_id = "$${dns_resource_group_id}"
      private_link_private_dns_zones_regex_filter = {
        enabled = false
      }
      auto_registration_zone_enabled = "$${primary_private_dns_auto_registration_zone_enabled}"
      auto_registration_zone_name    = "$${primary_auto_registration_zone_name}"
    }
    private_dns_resolver = {
      subnet_address_prefix = "$${primary_private_dns_resolver_subnet_address_prefix}"
      name                  = "$${primary_private_dns_resolver_name}"
    }
    bastion = {
      subnet_address_prefix = "$${primary_bastion_subnet_address_prefix}"
      name                  = "$${primary_bastion_host_name}"
      bastion_public_ip = {
        name = "$${primary_bastion_host_public_ip_name}"
      }
    }
    sidecar_virtual_network = {
      name          = "$${primary_sidecar_virtual_network_name}"
      address_space = ["$${primary_sidecar_virtual_network_address_space}"]
    }
  }
  secondary = {
    location = "$${starter_location_02}"
    /*
      NOTE: We are defaulting to a separate resource group for the hub per best practice for resiliency
      If you prefer to use the same resource group as the vwan, then set this to `$${connectivity_hub_vwan_resource_group_name}`
    */
    default_parent_id = "$${secondary_connectivity_resource_group_id}"
    enabled_resources = {
      firewall                              = "$${secondary_firewall_enabled}"
      bastion                               = "$${secondary_bastion_enabled}"
      virtual_network_gateway_express_route = "$${secondary_virtual_network_gateway_express_route_enabled}"
      virtual_network_gateway_vpn           = "$${secondary_virtual_network_gateway_vpn_enabled}"
      private_dns_zones                     = "$${secondary_private_dns_zones_enabled}"
      private_dns_resolver                  = "$${secondary_private_dns_resolver_enabled}"
      sidecar_virtual_network               = "$${secondary_sidecar_virtual_network_enabled}"
    }
    hub = {
      name           = "$${secondary_hub_name}"
      address_prefix = "$${secondary_hub_address_space}"
    }
    firewall = {
      name = "$${secondary_firewall_name}"
    }
    firewall_policy = {
      name = "$${secondary_firewall_policy_name}"
    }
    virtual_network_gateways = {
      express_route = {
        name = "$${secondary_virtual_network_gateway_express_route_name}"
      }
      vpn = {
        name = "$${secondary_virtual_network_gateway_vpn_name}"
      }
    }
    private_dns_zones = {
      parent_id = "$${dns_resource_group_id}"
      private_link_private_dns_zones_regex_filter = {
        enabled = true
      }
      auto_registration_zone_enabled = "$${secondary_private_dns_auto_registration_zone_enabled}"
      auto_registration_zone_name    = "$${secondary_auto_registration_zone_name}"
    }
    private_dns_resolver = {
      subnet_address_prefix = "$${secondary_private_dns_resolver_subnet_address_prefix}"
      name                  = "$${secondary_private_dns_resolver_name}"
    }
    bastion = {
      subnet_address_prefix = "$${secondary_bastion_subnet_address_prefix}"
      name                  = "$${secondary_bastion_host_name}"
      bastion_public_ip = {
        name = "$${secondary_bastion_host_public_ip_name}"
      }
    }
    sidecar_virtual_network = {
      name          = "$${secondary_sidecar_virtual_network_name}"
      address_space = ["$${secondary_sidecar_virtual_network_address_space}"]
    }
  }
}
