function Get-ServiceFabricApplicationPackageVersions
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $ApplicationTypeName
    )
    
    $versions = @{}

    $applicationTypes = Get-ServiceFabricApplicationType -ApplicationTypeName $ApplicationTypeName
    foreach ($applicationType in $applicationTypes)
    {
        $serviceTypes = Get-ServiceFabricServiceType -ApplicationTypeName $ApplicationTypeName -ApplicationTypeVersion $applicationType.ApplicationTypeVersion
        foreach ($serviceType in $serviceTypes)
        {
            $manifest = [xml](Get-ServiceFabricServiceManifest -ApplicationTypeName $applicationType.ApplicationTypeName -ApplicationTypeVersion $applicationType.ApplicationTypeVersion -ServiceManifestName $serviceType.ServiceManifestName)
            $packages = $manifest.GetElementsByTagName('CodePackage') + `
                        $manifest.GetElementsByTagName('ConfigPackage') + `
                        $manifest.GetElementsByTagName('DataPackage')

            foreach ($package in $packages)
            {
                $packageName = $package.GetAttribute('Name')
                $versions["$($serviceType.ServiceManifestName).$packageName.$($package.Version)"] = $true
            }
        }
    }
    
    return $versions
}