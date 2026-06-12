# Integration Guide: Using the vm_domain_controller Module

This guide shows how to integrate the reusable `vm_domain_controller` module into your existing Terraform infrastructure.

## Repository Integration

### 1. In your main.tf (where you're calling the module)

```hcl
# Example: In deploy/core/terraform/main.tf
module "domain_controllers" {
  source = "./modules/vm_domain_controller"

  # Required inputs - these would come from your existing locals and variables
  resource_group_name = module.resource_groups["adds"].name
  resource_group_location = var.azure_location
  region                  = local.selected_region

  # Subnet where DCs will be deployed - from your VNet module
  subnet_resource_id = module.network.subnets["subn-activedirectory-1"].resource_id

  # VM configurations - from your terraform.tfvars
  vms = var.vms

  # Tagging from your existing locals
  tags = local.resource_tags

  # Optional overrides
  # availability_set_name = "A${local.env_letter_map[var.environment]}W${var.vm_app_code}${var.vm_role}-avail"
  # admin_username = "domainadmin"
}
```

### 2. In your variables.tf (add if not exists)

```hcl
variable "vms" {
  description = "Virtual machine configurations"
  type = map(object({
    sku_size = string
    zone     = optional(string)
    network_interfaces = map(object({
      ip_configurations = map(object({
        private_ip_address            = optional(string)
        private_ip_address_allocation = optional(string, "Dynamic")
        private_ip_subnet_resource_id = optional(string)
      }))
    }))
    data_disks = optional(map(object({
      lun                  = number
      disk_size_gb         = number
      storage_account_type = optional(string, "Premium_LRS")
      caching             = optional(string, "ReadWrite")
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}
```

### 3. Outputs to access module resources

```hcl
# In your outputs.tf
output "domain_controller_ips" {
  description = "Private IP addresses of domain controllers"
  value       = module.domain_controllers.private_ip_addresses
}

output "domain_controller_names" {
  description = "Names of domain controller VMs"
  value       = module.domain_controllers.vm_names
}

output "availability_set_id" {
  description = "ID of the domain controller availability set"
  value       = module.domain_controllers.availability_set_id
}
```

## Using with your existing workspace variables

### Example for prd_eastus2

Your existing `prd_eastus2_terraform.tfvars` already has most of what you need:

```hcl
# This is already in your file - just update computer_name tags
vms = {
  DOM01 = {
    sku_size = "Standard_D2s_v3"
    zone     = "1"  # eastus2 supports zones
    network_interfaces = {
      primary = {
        ip_configurations = {
          internal = {
            private_ip_address            = "172.25.2.10"
            private_ip_address_allocation = "Static"
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
      computer_name = "APW000DC01"  # Make sure this is set
    }
  }
  DOM02 = {
    sku_size = "Standard_D2s_v3"
    zone     = "2"  # Different zone for HA
    network_interfaces = {
      primary = {
        ip_configurations = {
          internal = {
            private_ip_address            = "172.25.2.11"
            private_ip_address_allocation = "Static"
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
      computer_name = "APW000DC02"  # Make sure this is set
    }
  }
}
```

### Example for prd_centralus

For regions without availability zones:

```hcl
vms = {
  DOM01 = {
    sku_size = "Standard_D2s_v3"
    # No zone specified - will use availability set instead
    network_interfaces = {
      primary = {
        ip_configurations = {
          internal = {
            private_ip_address            = "172.24.2.10"
            private_ip_address_allocation = "Static"
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
      computer_name = "APW000DC03"
    }
  }
  DOM02 = {
    sku_size = "Standard_D2s_v3"
    network_interfaces = {
      primary = {
        ip_configurations = {
          internal = {
            private_ip_address            = "172.24.2.11"
            private_ip_address_allocation = "Static"
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
      computer_name = "APW000DC04"
    }
  }
}
```

## DNS Integration

After deploying the domain controllers, you can use their IPs for DNS:

```hcl
# In your locals_vnet.tf - this would reference the module outputs
locals {
  cross_region_dns_servers = try(
    length(module.domain_controllers.private_ip_addresses) > 0 ?
    { dns_servers = module.domain_controllers.private_ip_addresses } :
    null,
    null
  )
}
```

## Testing the Module

1. **Plan**: `terraform plan -target=module.domain_controllers`
2. **Apply**: `terraform apply -target=module.domain_controllers`
3. **Verify**: Check that VMs are created with correct zones/availability set
4. **Integration**: Update DNS settings to use the new DC IPs

## Key Benefits

✅ **Reusable**: Works across all regions (eastus2, centralus, etc.)  
✅ **HA-Ready**: Automatically uses zones or availability sets  
✅ **Consistent**: Uses your existing naming and tagging conventions  
✅ **Flexible**: Supports your current VM configuration patterns  
✅ **Monitored**: Includes Azure Monitor Agent by default  
✅ **Secure**: Stores credentials in Key Vault

The module will automatically detect if the region supports availability zones and configure high availability accordingly.
