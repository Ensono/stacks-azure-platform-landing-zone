# Stacks Azure Platform Landing Zone

This repository contains modules for deploying Azure Platform Landing Zones using [Azure Verified Modules (AVM)](https://aka.ms/avm).

## Modules

| Module | Description |
| ------ | ----------- |
| [Management Landing Zone](src/management/) | Management groups, policies, Log Analytics, and Data Collection Rules |
| [Connectivity Hub-Spoke](src/connectivity-hub-spoke/) | Hub-and-spoke network topology with Azure Firewall, Bastion, and DNS |
| [Connectivity Virtual WAN](src/connectivity-virtual-wan/) | Virtual WAN topology with secured hubs, Bastion, and DNS |

Each module includes a `README` with architecture diagrams, configuration examples in `deploy/terraform/examples/`, and unit tests in `deploy/terraform/tests/`.

## Technology Stack

| Component | Version |
| --------- | ------- |
| Terraform | ~> 1.12 |
| AzureRM Provider | ~> 4.0 |
| AzAPI Provider | ~> 2.0 |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.12
- [eirctl](https://github.com/Ensono/eirctl) task runner
- Azure CLI authenticated with appropriate permissions

## Development

Run from within a template directory:

| Command | Description |
| ------- | ----------- |
| `eirctl lint` | YAML lint → terraform fmt → validate → tflint |
| `eirctl scan` | Checkov security scan |
| `eirctl documentation` | Generate terraform-docs |
| `eirctl infrastructure:plan` | terraform init → plan |
| `eirctl infrastructure:apply` | terraform init → apply |

### Linting/Formatting

Run `eirctl lint` from the repository root for YAML and Terraform checks across all modules.

### Testing

Run `eirctl test:*` from the repository root to run unit tests for each module. For example, `eirctl test:management`.

## Contributing

1. Follow patterns in [.github/copilot-instructions.md](.github/copilot-instructions.md)
2. Keep hub_spoke and virtual_wan modules closely aligned where possible
3. Use Azure Verified Modules for new resources
4. Run `eirctl lint` before committing

## License

[MIT](LICENSE)
