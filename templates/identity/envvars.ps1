# Determine script root directory
$ScriptRoot = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

# If still empty, use current directory
if (-not $ScriptRoot) {
    $ScriptRoot = Get-Location
}

Push-Location -Path $ScriptRoot

#############################################################################
# LOCAL DEVELOPMENT ENVIRONMENT VARIABLES
# WARNING: These variables are for local development only.
# CI/CD pipelines use their own variable templates in:
# ./build/gha/pipelines/core/templates/variables/*.yml
#############################################################################

$variable_template_directory = ".\build\gha\pipelines\core\templates\variables"
$variable_templates = @("common_pipeline_variables.yml")

# Prompt user for Azure region selection
$regionChoice = Read-Host "Select Azure region:`n1) East US 2 (eastus2) [Default]`n2) Central US (centralus)`nEnter choice (1-2)"

# Set region based on user choice with default to eastus2
switch ($regionChoice) {
   "2" {
      $env:AZURE_LOCATION = "centralus"
      $variable_templates += "prd_centralus_pipeline_variables.yml"
      Write-Host "Selected: Central US (centralus)" -ForegroundColor Green
   }
   default {
      $env:AZURE_LOCATION = "eastus2"
      $variable_templates += "prd_eastus2_pipeline_variables.yml"
      Write-Host "Selected: East US 2 (eastus2)" -ForegroundColor Green
   }
}

# Load variables from YAML files and set them in current session
foreach ($template in $variable_templates) {
    $templateFile = Join-Path $variable_template_directory $template
    Write-Host "Loading variables from: $templateFile" -ForegroundColor Cyan

    if (Test-Path $templateFile) {
        # Import powershell-yaml module if not already loaded
        if (-not (Get-Module -Name powershell-yaml)) {
            Import-Module powershell-yaml -Force
        }

        $variables = (Get-Content -Path $templateFile | ConvertFrom-Yaml)

        foreach ($variable in $variables.GetEnumerator()) {
            $originalName = $variable.Name
            $value = $variable.Value

            # Handle TF_VAR_ prefixed variables
            if ($originalName.StartsWith("TF_VAR_")) {
                # Set the TF_VAR_ version for Terraform
                $tfVarName = "TF_VAR_" + $originalName.Substring(7).Replace("-", "_")
                Set-Item -Path "env:$tfVarName" -Value $value
                Write-Host "  $tfVarName = $value" -ForegroundColor Green

                # Also set the non-prefixed version for general use
                $shortName = $originalName.Substring(7).Replace("-", "_").ToUpper()
                Set-Item -Path "env:$shortName" -Value $value
                Write-Host "  $shortName = $value" -ForegroundColor Yellow
            } else {
                # Handle regular variables
                $envName = $originalName.Replace("-", "_").ToUpper()
                Set-Item -Path "env:$envName" -Value $value
                Write-Host "  $envName = $value" -ForegroundColor Green
            }
        }
    } else {
        Write-Warning "Template file not found: $templateFile"
    }
}

# Terraform input variables
# These should now be set from the YAML files above
$env:TF_FILE_LOCATION = ("deploy/{0}/terraform" -f $env:SERVICE_NAME)

<#
    LOCAL DEVELOPMENT USAGE:
    1. Copy envvars_sensative.ps1.template to envvars_sensative.ps1
    2. Update the sensitive variables with your local development values
    3. Source this file: . .\envvars.ps1
    4. Run taskctl commands locally

    PREREQUISITES:
    - Azure CLI installed
    - Terraform installed
    - PowerShell 7+
    - TaskCtl installed

    AUTHENTICATION SETUP:
    1. Create Service Principal:
       az login
       az ad sp create-for-rbac --name "sp-terraform-local" --role Contributor --scopes /subscriptions/{subscription-id}

    2. Configure envvars_sensative.ps1:
       $env:ARM_TENANT_ID = "<azure-tenant-guid>"
       $env:ARM_SUBSCRIPTION_ID = "<azure-subscription-guid>"
       $env:ARM_CLIENT_ID = "<service-principal-app-id>"
       $env:ARM_CLIENT_SECRET = "<service-principal-secret>"

    LOCAL DEVELOPMENT WORKFLOW:
    1. Source environment variables:
       . .\envvars.ps1

    4. Run Terraform operations using TaskCtl:
       taskctl terraform:init
       taskctl terraform:plan
       taskctl terraform:apply

    NOTE: For CI/CD pipelines, these values come from:
    - GitHub Secrets
    - Pipeline variable templates
    - Azure KeyVault

    IMPORTANT:
    - ⚠️ This file is for local development only
    - 🔒 Never commit envvars_sensative.ps1
    - 🔑 Service Principal needs appropriate RBAC permissions
    - 📁 Ensure correct working directory
    - 🌐 Verify correct subscription context

# Check if sensitive variables file exists and source it
$sensitiveVarsPath = Join-Path $ScriptRoot "envvars_sensative.ps1"
if (Test-Path $sensitiveVarsPath) {
    & $sensitiveVarsPath
} else {
    Write-Warning "envvars_sensative.ps1 not found. Please create it from the template if needed for local development."
}
#>

# ./envvars_sensative.ps1

<#
    Available Local TaskCtl Commands:

    Code Quality:
    - taskctl lint:yaml
    - taskctl lint:line_endings
    - taskctl lint:terraform:format
    - taskctl lint:terraform:validate
    - taskctl lint:terraform:tflint

    Security & Documentation:
    - taskctl scan:terraform:checkov
    - taskctl doc:terraform:terraform-docs

    Terraform Operations:
    - taskctl terraform:init
    - taskctl terraform:plan
    - taskctl terraform:apply

    NOTE: In CI/CD pipelines, these commands are orchestrated differently
    through GitHub Actions workflows
#>

<#
    Taskctl
#>
# taskctl lint:yaml
# taskctl lint:terraform:format
# taskctl lint:terraform:validate
# taskctl lint:terraform:tflint
# taskctl scan:terraform:checkov
# taskctl doc:terraform:terraform-docs

# taskctl terraform:init
# taskctl terraform:plan
# taskctl terraform:apply
