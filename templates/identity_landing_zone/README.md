# Stacks Ignite Five Below Identity Platform Landing Zone

[![Five Below Identity Core](https://github.com/FiveB-Infra/fb-identity/actions/workflows/pipeline.yml/badge.svg?branch=main)](https://github.com/FiveB-Infra/fb-identity/actions/workflows/pipeline.yml)

This Stacks Ignite root module orchestrates the provisioning of a Five Below Identity Platform Landing Zone using [Terraform](https://www.terraform.io/).

## Repository

The repository includes a terraform [root module](./deploy/) with code to deploy the identity resources, such as Azure AD and Microsoft Entra Domain Services (formerly Azure AD DS).

### Folder Structure

```text
├───.github
│   ├───actions
│   │   └───taskctl_install
│   └───workflows
├───.vscode
├───build
│   ├───gha
│   │   └───pipelines
│   │       └───core
│   │           └───templates
│   │               └───variables
│   ├───powershell
│   │   └───functions
│   └───taskctl
└───deploy
    └───core
        └───terraform
            └───workspace_variables

```

### Terraform Inputs

Inputs to the root module can be supplied in a number of ways:

- [terraform.tfvars](./deploy/core/terraform/terraform.tfvars)
- `workspace_variables/[prefix]_terraform.tfvars` - for example: [prd_eastus2_terraform.tfvars](./deploy/core/terraform/workspace_variables/prd_eastus2_terraform.tfvars)
- Pipeline environment variables `TF_VAR_[variable name]` - for example: [prd_eastus2_pipeline_variables.yml](./build/gha/pipelines/core/templates/variables/prd_eastus2_pipeline_variables.yml).

>[!NOTE]
> Variables that are common across all environments can be found in the [common_pipeline_variables.yml](./build/gha/pipelines/core/templates/variables/common_pipeline_variables.yml) file.

### Branch Rules

The repository has a [main branch ruleset](https://github.com/FiveB-Infra/fb-identity/settings/rules) enforced, which requires pull requests with successful validation and plans in UK South and UK West before any merges to `main`.

## Development Environment

Information for setting up your local development environment can be found below.

### Visual Studio Code

To align your Visual Studio Code settings with the project's recommended configuration:

1. Navigate to the `.vscode` directory at the root of the project.
2. Copy the contents of the `settings.sample.json` file to `settings.json`; or set these settings in the UI

### Dev Containers

Visual Studio Code [Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) (TBC).

### Manual Installations

#### Pre-commit

This repository uses the [pre-commit](https://pre-commit.com/) git hook framework, which can update and format some files enforcing our Terraform code module best practices. This repository has been tested with the following software versions:

- **Python**: [3.12.8](https://www.python.org/downloads/release/python-3128/)
- **Pre-commit**: `4.0.1`
- **Terraform**: [1.11.4](https://releases.hashicorp.com/terraform/1.11.4/)

Installation is simple and works cross platform. Use an elevated terminal when installing `pre-commit`. The framework can be installed and configured with a few steps:

One off actions to install `pre-commit`:

1. Install Python `3.12.8` ensuring that you enable the `Add to PATH` option on the Windows installer.
2. Install the pre-commit framework:  `pip3 install pre-commit==4.0.1`
3. Ensure `bash.exe` can be executed from a PowerShell terminal. If not, try adding `C:\Program Files\Git\bin` to your `Path` environment variable

Only required on newly cloned repositories:

1. Within the repo directory, run `pre-commit install` to set up the `pre-commit` git hook.
2. Within the repo directory, run `pre-commit install --hook-type commit-msg` to set up the `commit-msg` git hook.

To have all `pre-commit` hooks working, you will have to setup these dependencies locally. Place these files within a folder that has been added to your `PATH` environment variable:

- [terraform](https://releases.hashicorp.com/terraform/1.11.4/)
- [tfdocs](https://github.com/terraform-docs/terraform-docs)
- [tflint](https://github.com/terraform-linters/tflint)

>[!NOTE]
> To run the `pre-commit` hook against all files run `pre-commit run -a`.

Make code changes as usual, the git hooks will be triggered by `pre-commit` every time you use the `git commit` command.

A typical workflow would be:

1. `git pull`: the most recent changes into `main` from remote.
2. `git checkout -b [branch name]`: create a new branch to make code changes.
3. `git add .`: to stage all changed files.
4. `git commit -m '[commit message]'`: commit code changes.
5. `git push`: push committed changes to remote.

## Conventional Commits

This repo uses [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/). There is a `pre-commit` hook that will enforce the commit message format as per the [commit message guidelines](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines).

## Terraform Dependency Management

Managing dependencies in Terraform typically centers on updating the versions of child modules, whether they originate from the Terraform Registry or external sources such as GitHub.

### Automation

[Dependabot](https://github.com/dependabot) pipelines create pull requests (PRs) when an update is detected. Dependabot is a native GiHub application that only requires a simple configuration file: [dependabot.yml](./.github/dependabot.yml)

### Notifications

Dependabot configuration supports adding individual reviewers, or teams for all pull requests raised for a package manager.

[Dependabot Options - Reviewers](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference#reviewers--)

### Ownership

Ownership for managing dependency updates is the responsibility of the delivery team.

### Process

When a pull request is created, the CI/CD pipeline is triggered. During the `Build` stage, the pipeline validates both the code and documentation. The pipeline may initially fail when checking the `README.md` file, as this file is automatically generated from the code by pre-commit and includes the versions of child modules.

Steps:

1. Review the PR and understand from the child module release notes what changes the target version will introduce. Close the PR if the changes are not required.
2. Pull the PR branch locally
3. Run `pre-commit run -a` which runs pre-commit over all the files. This should result in the `README.md` file being updated
4. Push changes to the PR and ensure the PR pipeline completes successfully.
