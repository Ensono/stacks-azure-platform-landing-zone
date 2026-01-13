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
    connectivity_hub_primary_resource_group_name   = "rg-hub-$${starter_location_01_short}"
    connectivity_hub_secondary_resource_group_name = "rg-hub-$${starter_location_02_short}"
    dns_resource_group_name                        = "rg-hub-dns-$${starter_location_01_short}"
    ddos_resource_group_name                       = "rg-hub-ddos-$${starter_location_01_short}"

    # Resource names management
    ddos_protection_plan_name = "ddos-$${starter_location_01}"

    # Resource provisioning global connectivity
    ddos_protection_plan_enabled = false

    # Resource provisioning primary connectivity
    primary_firewall_enabled                                             = true
    primary_firewall_management_ip_enabled                               = true
    primary_virtual_network_gateway_express_route_enabled                = false
    primary_virtual_network_gateway_express_route_hobo_public_ip_enabled = false
    primary_virtual_network_gateway_vpn_enabled                          = false
    primary_private_dns_zones_enabled                                    = true
    primary_private_dns_auto_registration_zone_enabled                   = true
    primary_private_dns_resolver_enabled                                 = true
    primary_bastion_enabled                                              = false

    # Resource provisioning secondary connectivity
    secondary_firewall_enabled                                             = true
    secondary_firewall_management_ip_enabled                               = true
    secondary_virtual_network_gateway_express_route_enabled                = false
    secondary_virtual_network_gateway_express_route_hobo_public_ip_enabled = false
    secondary_virtual_network_gateway_vpn_enabled                          = false
    secondary_private_dns_zones_enabled                                    = true
    secondary_private_dns_auto_registration_zone_enabled                   = true
    secondary_private_dns_resolver_enabled                                 = true
    secondary_bastion_enabled                                              = false

    # Resource names primary connectivity
    primary_virtual_network_name                                 = "vnet-hub-$${starter_location_01_short}"
    primary_firewall_name                                        = "fw-hub-$${starter_location_01_short}"
    primary_firewall_policy_name                                 = "fwp-hub-$${starter_location_01_short}"
    primary_firewall_public_ip_name                              = "pip-fw-hub-$${starter_location_01_short}"
    primary_firewall_management_public_ip_name                   = "pip-fw-hub-mgmt-$${starter_location_01_short}"
    primary_route_table_firewall_name                            = "rt-hub-fw-$${starter_location_01_short}"
    primary_route_table_user_subnets_name                        = "rt-hub-std-$${starter_location_01_short}"
    primary_virtual_network_gateway_express_route_name           = "vgw-hub-er-$${starter_location_01_short}"
    primary_virtual_network_gateway_express_route_public_ip_name = "pip-vgw-hub-er-$${starter_location_01_short}"
    primary_virtual_network_gateway_vpn_name                     = "vgw-hub-vpn-$${starter_location_01_short}"
    primary_virtual_network_gateway_vpn_public_ip_name_1         = "pip-vgw-hub-vpn-$${starter_location_01_short}-001"
    primary_virtual_network_gateway_vpn_public_ip_name_2         = "pip-vgw-hub-vpn-$${starter_location_01_short}-002"
    primary_private_dns_resolver_name                            = "pdr-hub-dns-$${starter_location_01_short}"
    primary_bastion_host_name                                    = "bas-hub-$${starter_location_01_short}"
    primary_bastion_host_public_ip_name                          = "pip-bastion-hub-$${starter_location_01_short}"

    # Resource names secondary connectivity
    secondary_virtual_network_name                                 = "vnet-hub-$${starter_location_02_short}"
    secondary_firewall_name                                        = "fw-hub-$${starter_location_02_short}"
    secondary_firewall_policy_name                                 = "fwp-hub-$${starter_location_02_short}"
    secondary_firewall_public_ip_name                              = "pip-fw-hub-$${starter_location_02_short}"
    secondary_firewall_management_public_ip_name                   = "pip-fw-hub-mgmt-$${starter_location_02_short}"
    secondary_route_table_firewall_name                            = "rt-hub-fw-$${starter_location_02_short}"
    secondary_route_table_user_subnets_name                        = "rt-hub-std-$${starter_location_02_short}"
    secondary_virtual_network_gateway_express_route_name           = "vgw-hub-er-$${starter_location_02_short}"
    secondary_virtual_network_gateway_express_route_public_ip_name = "pip-vgw-hub-er-$${starter_location_02_short}"
    secondary_virtual_network_gateway_vpn_name                     = "vgw-hub-vpn-$${starter_location_02_short}"
    secondary_virtual_network_gateway_vpn_public_ip_name_1         = "pip-vgw-hub-vpn-$${starter_location_02_short}-001"
    secondary_virtual_network_gateway_vpn_public_ip_name_2         = "pip-vgw-hub-vpn-$${starter_location_02_short}-002"
    secondary_private_dns_resolver_name                            = "pdr-hub-dns-$${starter_location_02_short}"
    secondary_bastion_host_name                                    = "bas-hub-$${starter_location_02_short}"
    secondary_bastion_host_public_ip_name                          = "pip-bastion-hub-$${starter_location_02_short}"

    # Private DNS Zones primary
    primary_auto_registration_zone_name = "$${starter_location_01}.azure.local"

    # Private DNS Zones secondary
    secondary_auto_registration_zone_name = "$${starter_location_02}.azure.local"

    # IP Ranges Primary
    # Regional Address Space: 10.0.0.0/16
    primary_hub_address_space                          = "10.0.0.0/16"
    primary_hub_virtual_network_address_space          = "10.0.0.0/22"
    primary_firewall_subnet_address_prefix             = "10.0.0.0/26"
    primary_firewall_management_subnet_address_prefix  = "10.0.0.192/26"
    primary_bastion_subnet_address_prefix              = "10.0.0.64/26"
    primary_gateway_subnet_address_prefix              = "10.0.0.128/27"
    primary_private_dns_resolver_subnet_address_prefix = "10.0.0.160/28"

    # IP Ranges Secondary
    # Regional Address Space: 10.1.0.0/16
    secondary_hub_address_space                          = "10.1.0.0/16"
    secondary_hub_virtual_network_address_space          = "10.1.0.0/22"
    secondary_firewall_subnet_address_prefix             = "10.1.0.0/26"
    secondary_firewall_management_subnet_address_prefix  = "10.1.0.192/26"
    secondary_bastion_subnet_address_prefix              = "10.1.0.64/26"
    secondary_gateway_subnet_address_prefix              = "10.1.0.128/27"
    secondary_private_dns_resolver_subnet_address_prefix = "10.1.0.160/28"
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
--- Connectivity - Hub and Spoke Virtual Network ---
You can use this section to customize the hub virtual networking that will be deployed.
*/

connectivity_resource_groups = {
  ddos = {
    name     = "$${ddos_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = "$${ddos_protection_plan_enabled}"
    }
  }
  vnet_primary = {
    name     = "$${connectivity_hub_primary_resource_group_name}"
    location = "$${starter_location_01}"
    settings = {
      enabled = true
    }
  }
  vnet_secondary = {
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

hub_and_spoke_networks_settings = {
  enabled_resources = {
    ddos_protection_plan = "$${ddos_protection_plan_enabled}"
  }
  ddos_protection_plan = {
    name                = "$${ddos_protection_plan_name}"
    resource_group_name = "$${ddos_resource_group_name}"
    location            = "$${starter_location_01}"
  }
}

hub_virtual_networks = {
  primary = {
    location          = "$${starter_location_01}"
    default_parent_id = "$${primary_connectivity_resource_group_id}"
    enabled_resources = {
      firewall                              = "$${primary_firewall_enabled}"
      bastion                               = "$${primary_bastion_enabled}"
      virtual_network_gateway_express_route = "$${primary_virtual_network_gateway_express_route_enabled}"
      virtual_network_gateway_vpn           = "$${primary_virtual_network_gateway_vpn_enabled}"
      private_dns_zones                     = "$${primary_private_dns_zones_enabled}"
      private_dns_resolver                  = "$${primary_private_dns_resolver_enabled}"
    }
    hub_virtual_network = {
      name                          = "$${primary_virtual_network_name}"
      address_space                 = ["$${primary_hub_virtual_network_address_space}"]
      routing_address_space         = ["$${primary_hub_address_space}"]
      route_table_name_firewall     = "$${primary_route_table_firewall_name}"
      route_table_name_user_subnets = "$${primary_route_table_user_subnets_name}"
      subnets                       = {}
    }
    firewall = {
      subnet_address_prefix            = "$${primary_firewall_subnet_address_prefix}"
      management_subnet_address_prefix = "$${primary_firewall_management_subnet_address_prefix}"
      name                             = "$${primary_firewall_name}"
      default_ip_configuration = {
        public_ip_config = {
          name = "$${primary_firewall_public_ip_name}"
        }
      }
      management_ip_enabled = "$${primary_firewall_management_ip_enabled}"
      management_ip_configuration = {
        public_ip_config = {
          name = "$${primary_firewall_management_public_ip_name}"
        }
      }
    }
    firewall_policy = {
      name = "$${primary_firewall_policy_name}"
    }
    virtual_network_gateways = {
      subnet_address_prefix = "$${primary_gateway_subnet_address_prefix}"
      express_route = {
        name                                  = "$${primary_virtual_network_gateway_express_route_name}"
        hosted_on_behalf_of_public_ip_enabled = "$${primary_virtual_network_gateway_express_route_hobo_public_ip_enabled}"
        ip_configurations = {
          default = {
            public_ip = {
              name = "$${primary_virtual_network_gateway_express_route_public_ip_name}"
            }
          }
        }
      }
      vpn = {
        name = "$${primary_virtual_network_gateway_vpn_name}"
        ip_configurations = {
          active_active_1 = {
            public_ip = {
              name = "$${primary_virtual_network_gateway_vpn_public_ip_name_1}"
            }
          }
          active_active_2 = {
            public_ip = {
              name = "$${primary_virtual_network_gateway_vpn_public_ip_name_2}"
            }
          }
        }
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
  }
  secondary = {
    location          = "$${starter_location_02}"
    default_parent_id = "$${secondary_connectivity_resource_group_id}"
    enabled_resources = {
      firewall                              = "$${secondary_firewall_enabled}"
      bastion                               = "$${secondary_bastion_enabled}"
      virtual_network_gateway_express_route = "$${secondary_virtual_network_gateway_express_route_enabled}"
      virtual_network_gateway_vpn           = "$${secondary_virtual_network_gateway_vpn_enabled}"
      private_dns_zones                     = "$${secondary_private_dns_zones_enabled}"
      private_dns_resolver                  = "$${secondary_private_dns_resolver_enabled}"
    }
    hub_virtual_network = {
      name                          = "$${secondary_virtual_network_name}"
      address_space                 = ["$${secondary_hub_virtual_network_address_space}"]
      routing_address_space         = ["$${secondary_hub_address_space}"]
      route_table_name_firewall     = "$${secondary_route_table_firewall_name}"
      route_table_name_user_subnets = "$${secondary_route_table_user_subnets_name}"
      subnets                       = {}
    }
    firewall = {
      subnet_address_prefix            = "$${secondary_firewall_subnet_address_prefix}"
      management_subnet_address_prefix = "$${secondary_firewall_management_subnet_address_prefix}"
      name                             = "$${secondary_firewall_name}"
      default_ip_configuration = {
        public_ip_config = {
          name = "$${secondary_firewall_public_ip_name}"
        }
      }
      management_ip_enabled = "$${secondary_firewall_management_ip_enabled}"
      management_ip_configuration = {
        public_ip_config = {
          name = "$${secondary_firewall_management_public_ip_name}"
        }
      }
    }
    firewall_policy = {
      name = "$${secondary_firewall_policy_name}"
    }
    virtual_network_gateways = {
      subnet_address_prefix = "$${secondary_gateway_subnet_address_prefix}"
      express_route = {
        name                                  = "$${secondary_virtual_network_gateway_express_route_name}"
        hosted_on_behalf_of_public_ip_enabled = "$${secondary_virtual_network_gateway_express_route_hobo_public_ip_enabled}"
        ip_configurations = {
          default = {
            public_ip = {
              name = "$${secondary_virtual_network_gateway_express_route_public_ip_name}"
            }
          }
        }
      }
      vpn = {
        name = "$${secondary_virtual_network_gateway_vpn_name}"
        ip_configurations = {
          active_active_1 = {
            public_ip = {
              name = "$${secondary_virtual_network_gateway_vpn_public_ip_name_1}"
            }
          }
          active_active_2 = {
            public_ip = {
              name = "$${secondary_virtual_network_gateway_vpn_public_ip_name_2}"
            }
          }
        }
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
  }
}
