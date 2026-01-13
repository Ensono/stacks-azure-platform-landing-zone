# Stacks Azure Platform Landing Zone Starter Module - Connectivity - Virtual WAN

This module is part of the Stacks Azure Platform Landing Zone solution. It is a complete implementation of a Connectivity Landing Zone with a Virtual WAN network topology using Azure Verified Modules.

## Features

- Hub Networking with Virtual WAN
- Private DNS Zones for Private Link
- Optional DDOS Protection Plan
- Azure Firewall

>[!NOTE]
> The module can be used independently if needed. Example `tfvars` files can be found in the [examples](./deploy/terraform/examples/) directory for that use case.

### Running Directly

#### Run the local examples

Create a `terraform.tfvars` file in the root of the module directory with the following content, replacing the placeholders with the actual values:

```hcl
starter_locations = ["uksouth", "ukwest"]
subscription_ids  = {
  "connectivity"  = "00000000-0000-0000-0000-000000000000"
}
```

```powershell
terraform init
terraform apply -var-file ./examples/multi_region/virtual_wan_minimal.tfvars
```
