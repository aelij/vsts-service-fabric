[CmdletBinding()]
PARAM()

Trace-VstsEnteringInvocation $MyInvocation
try
{
    . "$PSScriptRoot/Update-ServiceFabricApplicationPackageVersions.ps1"
    . "$PSScriptRoot/Get-ServiceFabricApplicationPackageVersions.ps1"

    $packagePath = Get-VstsInput -Name PackagePath -Require
    
    $DifferentialPackage = Get-VstsInput -Name DifferentialPackage
    if ($DifferentialPackage -eq 'true')
    {
        Import-Module $PSScriptRoot\ps_modules\ServiceFabricHelpers

        $serviceConnectionName = Get-VstsInput -Name ServiceConnectionName -Require
        $connectedServiceEndpoint = Get-VstsEndpoint -Name $serviceConnectionName -Require
        $clusterConnectionParameters = @{}
        Connect-ServiceFabricClusterFromServiceEndpoint -ClusterConnectionParameters $clusterConnectionParameters -ConnectedServiceEndpoint $connectedServiceEndpoint

        $applicationManifestPath = [IO.Path]::Combine($packagePath, 'ApplicationManifest.xml')
        $applicationManifest = [xml](Get-Content $applicationManifestPath)
        $versions = Get-ServiceFabricApplicationPackageVersions -ApplicationTypeName $applicationManifest.ApplicationManifest.ApplicationTypeName
    }
    
    Update-ServiceFabricApplicationPackageVersions `
        -PackagePath $packagePath `
		-VersionMode (Get-VstsInput -Name VersionMode -Require) `
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