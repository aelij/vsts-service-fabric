[CmdletBinding()]
PARAM()

Trace-VstsEnteringInvocation $MyInvocation
try
{
    . "$PSScriptRoot/Update-ServiceFabricApplicationPackageVersions.ps1"
    . "$PSScriptRoot/Get-ServiceFabricApplicationPackageVersions.ps1"

	$DifferentialPackage = Get-VstsInput -Name DifferentialPackage
	if ($DifferentialPackage -eq 'true')
	{
        Import-Module $PSScriptRoot\ps_modules\ServiceFabricHelpers

		$serviceConnectionName = Get-VstsInput -Name ServiceConnectionName -Require
		$connectedServiceEndpoint = Get-VstsEndpoint -Name $serviceConnectionName -Require
		$clusterConnectionParameters = @{}
		Connect-ServiceFabricClusterFromServiceEndpoint -ClusterConnectionParameters $clusterConnectionParameters -ConnectedServiceEndpoint $connectedServiceEndpoint

		if ((Get-VstsInput -Name ApplicationNameSource -Require) -eq 'PublishParametersFile')
		{
			$parametersFilePath = Get-VstsInput -Name PublishParametersFilePath -Require
			$parametersFile = [xml](Get-Content $parametersFilePath)
			$applicationName = $parametersFile.Application.Name
		}
		else
		{
			$applicationName = Get-VstsInput -Name ApplicationName -Require
		}

        $versions = Get-ServiceFabricApplicationPackageVersions $applicationName			
	}
	
	Update-ServiceFabricApplicationPackageVersions `
        -PackagePath (Get-VstsInput -Name PackagePath -Require) `
        -ApplicationVersion (Get-VstsInput -Name ApplicationVersion -Require) `
        -ServiceVersion (Get-VstsInput -Name ServiceVersion -Require) `
        -CodePackageHash:((Get-VstsInput -Name CodePackageMode -Require) -eq 'Hash') `
        -ConfigPackageHash:((Get-VstsInput -Name ConfigPackageMode -Require) -eq 'Hash') `
        -DataPackageHash:((Get-VstsInput -Name DataPackageMode -Require) -eq 'Hash') `
        -CodePackageVersion (Get-VstsInput -Name CodePackageVersion) `
        -ConfigPackageVersion (Get-VstsInput -Name ConfigPackageVersion) `
        -DataPackageVersion (Get-VstsInput -Name DataPackageVersion) `
        -DiffPackageVersions $versions `
        -HashAlgorithm (Get-VstsInput -Name HashAlgorithm -Require) `
        -HashExcludes (Get-VstsInput -Name HashExcludes -Require).Split(';')
}
finally
{
    Trace-VstsLeavingInvocation $MyInvocation
}