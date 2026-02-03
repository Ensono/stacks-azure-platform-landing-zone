variable "private_endpoints_nsg" {
  type = object({
    enabled = optional(bool, true)
  })

  default = {
    enabled = true
  }

  description = <<-DESCRIPTION
    Configuration for the Network Security Group on the private endpoints subnet.

    NSG provides:
    - Centralized access control for private endpoints
    - Visibility through NSG flow logs
    - Compliance auditing capability

    Microsoft recommends using NSG on private endpoint subnets to control and log access.
    See: https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network

    - `enabled` - (Optional) Deploy NSG on private endpoints subnet. Defaults to `true`.

    Note: When `enabled = true`, an NSG with default rules is created:
    - AllowVNetInbound (priority 100): Allow traffic from VirtualNetwork
    - DenyInternetInbound (priority 4096): Deny traffic from Internet
  DESCRIPTION
}
