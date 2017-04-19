function Get-ServiceFabricApplicationPackageVersions
{
	[CmdletBinding()]
	Param
	(
		[Parameter(IsMandatory=$true)]
		[uri] $ApplicationName
	)
	
	$versions = @{}

	$application = Get-ServiceFabricApplication -ApplicationName $ApplicationName
	if ($application)
	{
		$serviceTypes = Get-ServiceFabricServiceType -ApplicationTypeName $application.ApplicationTypeName -ApplicationTypeVersion $application.ApplicationTypeVersion
		foreach ($serviceType in $serviceTypes)
		{
			$manifest = [xml](Get-ServiceFabricServiceManifest -ApplicationTypeName $application.ApplicationTypeName -ApplicationTypeVersion $application.ApplicationTypeVersion -ServiceManifestName $serviceType.ServiceManifestName)
			$packages = $manifest.GetElementsByTagName('CodePackage') + `
                        $manifest.GetElementsByTagName('ConfigPackage') + `
                        $manifest.GetElementsByTagName('DataPackage')

			foreach ($package in $packages)
            {
                $packageName = $package.GetAttribute('Name')
                $versions["$($serviceType.ServiceManifestName).$packageName"] = $package.Version
            }
		}
	}
	
	return $versions
}