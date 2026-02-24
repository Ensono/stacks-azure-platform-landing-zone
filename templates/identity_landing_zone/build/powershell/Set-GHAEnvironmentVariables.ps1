[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]
	$variableDirectory,

	[Parameter(Mandatory = $true)]
	[array]
	$variableTemplates
)

$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

$functions = (
	"Retry-Command.ps1",
	"Install-PowerShellModules.ps1"
)

foreach ($function in $functions) {
    Write-Information -MessageData ("Dot-sourcing function '{0}'" -f $function)
	. ("./build/powershell/functions/{0}" -f $function)
}

Install-PowerShellModules -moduleNames ("powershell-yaml") | Out-Null

foreach ($template in $variableTemplates) {

	$templateFile = ("{0}/{1}" -f $variableDirectory, $template)
	Write-Information -MessageData ("`nSetting enviroment variables from '{0}'" -f $templateFile)
	$variables = (Get-Content -Path $templateFile | ConvertFrom-Yaml)

	$terraformPrefix = "TF_VAR_"

	foreach ($variable in $variables.GetEnumerator()) {
		if (($variable.name).StartsWith($terraformPrefix)) {
			$name = $variable.Name.Replace("-", "_")
			$trimmedName = ($variable.Name.Replace("-", "_")).Replace($terraformPrefix, "").ToUpper()
			$value = $variable.Value

			Write-Information -MessageData ("`nName '{0}`nValue '{1}'" -f $trimmedName, $value)
			("{0}={1}" -f $trimmedName, $value) >> $env:GITHUB_ENV
		} else {
			$name = ($variable.Name.Replace("-", "_")).ToUpper()
			$value = $variable.Value
		}

		Write-Information -MessageData ("`nName '{0}`nValue '{1}'" -f $name, $value)
		("{0}={1}" -f $name, $value) >> $env:GITHUB_ENV
	}

}
