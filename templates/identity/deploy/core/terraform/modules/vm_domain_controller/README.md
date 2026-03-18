# Domain Controller VM Module

This module creates Windows Server virtual machines configured as domain controllers in Azure. It supports both availability zones (where available) and availability sets for high availability.

## Features

- **High Availability**: Automatically uses availability zones where supported, falls back to availability sets
- **Flexible Networking**: Supports multiple network interfaces and IP configurations per VM
- **Customizable Storage**: Configurable OS disk and optional data disks
- **Security Hardening**: Configurable security settings including encryption at host
- **Monitoring Ready**: Includes Azure Monitor Agent extension by default
- **Consistent Naming**: Follows enterprise naming conventions with geo codes

## Usage

```hcl
module "domain_controllers" {
  source = "./modules/vm_domain_controller"

  # Basic configuration
  azure_location      = "eastus2"
  resource_group_name = "rg-eastus2-company-prd-identity"
  company_name_short  = "comp"
  environment         = "prd"
  default_subnet_id   = "/subscriptions/.../subnets/subnet-ad"

  # VM configuration
  vms = {
    DOM01 = {
      sku_size = "Standard_D2s_v3"
      zone     = "1"  # Optional, will use availability set if not specified
      network_interfaces = {
        primary = {
          ip_configurations = {
            internal = {
              private_ip_address_allocation = "Static"
              private_ip_address           = "10.0.1.10"
            }
          }
        }
      }
      data_disks = {
        data01 = {
          lun                  = 1
          disk_size_gb         = 100
          storage_account_type = "Premium_LRS"
          caching              = "ReadOnly"
        }
      }
      tags = {
        computer_name = "COMPRDDOM01"
      }
    }
    DOM02 = {
      sku_size = "Standard_D2s_v3"
      zone     = "2"
      network_interfaces = {
        primary = {
          ip_configurations = {
            internal = {
              private_ip_address_allocation = "Static"
              private_ip_address           = "10.0.1.11"
            }
          }
        }
      }
      tags = {
        computer_name = "COMPRDDOM02"
      }
    }
  }

  # Common tags
  tags = {
    Project     = "Identity Infrastructure"
    Owner       = "IT Operations"
    CostCenter  = "12345"
  }
}
```

## Advanced Usage

### Custom OS Image
```hcl
module "domain_controllers" {
  # ... other configuration

  os_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}
```

### Custom VM Settings
```hcl
module "domain_controllers" {
  # ... other configuration

  vm_settings = {
    encryption_at_host_enabled = true
    secure_boot_enabled        = true
    vtpm_enabled               = true
    enable_automatic_updates   = false
  }
}
```

### Multiple Network Interfaces
```hcl
vms = {
  DOM01 = {
    sku_size = "Standard_D2s_v3"
    network_interfaces = {
      primary = {
        ip_configurations = {
          internal = {
            private_ip_address_allocation = "Static"
            private_ip_address           = "10.0.1.10"
          }
        }
      }
      secondary = {
        ip_configurations = {
          management = {
            private_ip_address_allocation = "Dynamic"
            private_ip_subnet_resource_id = "/subscriptions/.../subnets/management"
          }
        }
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6 |
| azurerm | >= 3.71, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.71, < 5.0 |

## Resources

| Name | Type |
|------|------|
| azurerm_availability_set.domain_controller_aset | resource |
| azurerm_client_config.current | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| domain_controller | Azure/avm-res-compute-virtualmachine/azurerm | 0.19.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vms | Map of VM configurations for domain controllers | `map(object)` | n/a | yes |
| azure_location | The Azure location/region where resources will be deployed | `string` | n/a | yes |
| resource_group_name | The name of the resource group where domain controller resources will be created | `string` | n/a | yes |
| company_name_short | Short company name for resource naming | `string` | n/a | yes |
| default_subnet_id | Default subnet ID for domain controllers when subnet is not specified in VM configuration | `string` | n/a | yes |
| vm_resource_prefix | The prefix for virtual machines names | `string` | `"vm"` | no |
| environment | Environment name (e.g., prd, dev, tst) | `string` | `"prd"` | no |
| tags | Common tags to apply to all resources | `map(string)` | `{}` | no |
| enable_telemetry | Enable telemetry for the VM module | `bool` | `false` | no |
| os_image | Operating system image configuration | `object` | Windows Server 2025 | no |
| os_disk_config | OS disk configuration | `object` | 128GB StandardSSD | no |
| vm_settings | VM security and management settings | `object` | Standard settings | no |
| availability_set_config | Availability set configuration | `object` | Standard config | no |
| extensions | VM extensions to install | `map(object)` | Azure Monitor Agent | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_names | Resource names of every VM created |
| vm_resource_ids | Resource IDs of every VM created |
| vm_computer_names | Computer names of every VM created |
| admin_password | Admin password for each VM (sensitive) |
| admin_username | Admin username for each VM |
| network_interfaces | Network interface details for each VM |
| private_ip_addresses | Private IP addresses for each VM |
| availability_set_id | ID of the availability set (if created) |
| region_supports_zones | Whether the selected region supports availability zones |
| vm_details | Comprehensive VM details |

## Supported Regions

The module includes geo-code mappings for common Azure regions and automatically detects availability zone support. Supported regions include:

- **US**: East US, East US 2, West US, West US 2, West US 3, Central US, North Central US, South Central US, West Central US
- **Europe**: North Europe, West Europe, France Central, Germany West Central, Norway East, Switzerland North, UK South, UK West
- **Asia Pacific**: Southeast Asia, East Asia, Japan East, Japan West, Korea Central, Australia East, Australia Southeast
- **Other**: Canada Central, Canada East, Brazil South, South Africa North, India regions

## Notes

- VMs are automatically placed in availability zones if the region supports them, otherwise an availability set is created
- Computer names are automatically truncated to 15 characters to comply with Windows NetBIOS naming requirements
- The module uses consistent naming patterns with geo codes for better resource organization
- Extensions can be customized by overriding the `extensions` variable
- All resources inherit common tags plus any VM-specific tags
