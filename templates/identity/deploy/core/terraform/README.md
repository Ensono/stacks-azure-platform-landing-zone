## Identity Landing Zone Terraform Module

This module deploys ADDS hosting infrastructure in Azure with:

- AVM-based resource groups and VM modules
- Key Vault private endpoint and write-only secret handling
- Identity VNet DNS configured for the connectivity DNS proxy path
- Optional ADDS DNS forwarder configuration via VM extension

Run `terraform-docs` after changes to regenerate full input/output tables.
