## Known Issues

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.46.0 |
| random | >= 3.6.0, < 4.0.0 |
| terraform | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| az\_naming | git::https://github.com/FiveB-Infra/fb-naming.git | v2025.11.21.6 |
| key\_vault | ./modules/az_keyvault | n/a |
| network | ./modules/az_network | n/a |
| remote\_state | ./modules/tf_remote_state | n/a |
| resource\_groups | Azure/avm-res-resources-resourcegroup/azurerm | 0.2.1 |
| tagging | git::https://github.com/FiveB-Infra/fb-tagging.git | v2025.10.10.7 |
| vm\_domain\_controller | ./modules/vm_domain_controller | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.vm_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.vm_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_virtual_network_dns_servers.vnet_dns](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_dns_servers) | resource |
| [random_password.vm_admin_temp](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.vm_password_update](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [azurerm_client_config.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| Application | Identifies the application related to the resource. | `string` | n/a | yes |
| ApplicationCode | Links the application to the approved application list. | `string` | n/a | yes |
| CostCode | The date the ARM deployment for the resource occurred, for example “2019-08-27T16:30:10.7936410+01:00”.(The use of the UTC time zone is recommended for consistency) | `string` | n/a | yes |
| CreatedBy | Email address of the engineer who provisioned the resource. | `string` | n/a | yes |
| CreatedOn | The date the ARM deployment for the resource occurred, for example “2019-08-27T16:30:10.7936410+01:00”.(The use of the UTC time zone is recommended for consistency). | `string` | n/a | yes |
| Criticality | Denotes the importance of a service and availability requirement. E.g. Low (95%), Medium (99.5%), High (99.9%) and Critical (99.95%) | `string` | n/a | yes |
| Environment | Product lifecycle stage. | `string` | n/a | yes |
| Monitoring | The monitoring solution used. | `string` | n/a | yes |
| Owner | TBusiness Owner of the Resource Group/Resource. | `string` | n/a | yes |
| ProductDomain | Identifies the product group and associated development team. | `string` | n/a | yes |
| Role | Roles of service | `string` | n/a | yes |
| azure\_location | The Azure location to target all resources. | `string` | n/a | yes |
| azure\_resource\_group\_management\_lock\_level | Optional: The level of Management Lock apply to Resource Groups | `string` | `""` | no |
| component\_names | A list of component names which can be used in naming of resources used with different module calls. | `set(string)` | n/a | yes |
| environment | The Azure environment to target all resources. | `string` | n/a | yes |
| lz\_short\_code | A short code for the LZ to use in naming of resources. | `string` | n/a | yes |
| vm\_admin\_username | Admin username for domain controller VMs | `string` | `"azureuser"` | no |
| vm\_app\_code | Application code for VM naming per HLD (e.g., 000 for Active Directory) | `string` | `"000"` | no |
| vm\_password\_version | Increment this value to rotate the VM admin password. Uses value\_wo\_version for write-only Key Vault secret. | `number` | `1` | no |
| vm\_role | VM role abbreviation for naming per HLD (e.g., DC for Domain Controller, APP, DB) | `string` | `"DC"` | no |
| vm\_settings | VM security and management settings - Trusted Launch enabled by default for Gen 2 VMs | <pre>object({<br/>    encryption_at_host_enabled = optional(bool, true)<br/>    allow_extension_operations = optional(bool, true)<br/>    enable_automatic_updates   = optional(bool, true)<br/>    patch_assessment_mode      = optional(string, "AutomaticByPlatform")<br/>    patch_mode                 = optional(string, "AutomaticByPlatform")<br/>    provision_vm_agent         = optional(bool, true)<br/>    secure_boot_enabled        = optional(bool, true)<br/>    vtpm_enabled               = optional(bool, true)<br/>    boot_diagnostics           = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "allow_extension_operations": true,<br/>  "boot_diagnostics": true,<br/>  "enable_automatic_updates": true,<br/>  "encryption_at_host_enabled": true,<br/>  "patch_assessment_mode": "AutomaticByPlatform",<br/>  "patch_mode": "AutomaticByPlatform",<br/>  "provision_vm_agent": true,<br/>  "secure_boot_enabled": true,<br/>  "vtpm_enabled": true<br/>}</pre> | no |
| vms | Map of VM configurations for domain controllers | <pre>map(object({<br/>    zone     = optional(string)<br/>    sku_size = string<br/>    network_interfaces = map(object({<br/>      ip_configurations = map(object({<br/>        private_ip_address            = optional(string)<br/>        private_ip_address_allocation = string<br/>        private_ip_subnet_resource_id = optional(string)<br/>      }))<br/>    }))<br/>    data_disks = optional(map(object({<br/>      lun                  = number<br/>      disk_size_gb         = number<br/>      storage_account_type = string<br/>      caching              = string<br/>    })), {})<br/>    tags = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| vnet\_address\_space | The address space applied to the virtual network. You can supply more than one address space. | `list(string)` | n/a | yes |
| vnet\_nsg\_rules | A map of NSG rules to create. | <pre>map(object({<br/>    name                       = string<br/>    priority                   = number<br/>    direction                  = string<br/>    access                     = string<br/>    protocol                   = string<br/>    source_port_range          = string<br/>    destination_port_range     = string<br/>    source_address_prefix      = string<br/>    destination_address_prefix = string<br/>  }))</pre> | `{}` | no |
| vnet\_subnets | A map of subnets to create. | <pre>map(object({<br/>    name                                          = string<br/>    address_prefixes                              = list(string)<br/>    nsg_rule_names                                = list(string)<br/>    default_outbound_access_enabled               = optional(bool, false)<br/>    route_names                                   = optional(list(string), [])<br/>    private_endpoint_network_policies             = optional(string, "Disabled")<br/>    private_link_service_network_policies_enabled = optional(bool, true)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| private\_ip\_addresses | Private IP addresses for each VM |
| subscription\_id | The subscription ID of the Identity subscription. |
<!-- END_TF_DOCS -->
