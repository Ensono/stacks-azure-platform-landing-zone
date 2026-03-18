# Stacks Azure Landing Zone Identity

This template deploys the Identity Landing Zone baseline for hosting Active Directory Domain Services (ADDS) on Azure virtual machines.

## ADR Scope Alignment

- Deploys ADDS hosting infrastructure in a dedicated identity scope (resource groups, VNet, domain controller VMs).
- Uses secure secret handling with ephemeral password generation and Key Vault write-only secret storage.
- Configures Identity VNet DNS to use connectivity DNS proxy/firewall path.
- Configures ADDS DNS forwarders on domain controller VMs using a VM extension.

## Terraform Entry Point

- Root module: [deploy/core/terraform](deploy/core/terraform)
- Common variables: [deploy/core/terraform/terraform.tfvars](deploy/core/terraform/terraform.tfvars)
- Environment overrides:
    - [deploy/core/terraform/workspace_variables/prd_eastus2_terraform.tfvars](deploy/core/terraform/workspace_variables/prd_eastus2_terraform.tfvars)
    - [deploy/core/terraform/workspace_variables/prd_centralus_terraform.tfvars](deploy/core/terraform/workspace_variables/prd_centralus_terraform.tfvars)

## Notes

- This template intentionally avoids external project-specific naming and tagging modules.
- Naming is generated via Azure naming module conventions.
- Remote state locations are parameterized via `remote_state_configs` and should be set per environment.
