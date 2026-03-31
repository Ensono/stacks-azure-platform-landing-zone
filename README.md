# Stacks Azure Platform Landing Zone

This repository contains foundational modules that provide an opinionated approach for deploying and managing the core platform capabilities of an [Azure landing zone architecture](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/#azure-landing-zone-architecture) using Azure Verified Modules for Terraform.

## Documentation

Documentation is stored with the code in [Asciidoc](https://docs.asciidoctor.org/) format. It is in the [docs](/docs/) directory of the repository.

### Repository Development Guide

This is located in `docs/repository/index.adoc`

A PDF version can be generated locally by running:

```bash
eirctl docs
```

The guide can then be located in `outputs/docs/pdf`.

>[!NOTE]
> This file is also published as a GitHub release asset.

### Module Usage Guides

These are packaged inside the zip files for each module as a `README.md`.

## License

Copyright (c) 2026 Ensono

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
