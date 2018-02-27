function Update-ServiceFabricApplicationPackageVersions
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $PackagePath,

        [Parameter()]
        [string] $ApplicationVersion,

        [Parameter()]
        [string] $ServiceVersion,

        [Parameter()]
        [string] $CodePackageVersion,

        [Parameter()]
        [switch] $CodePackageHash,

        [Parameter()]
        [string] $ConfigPackageVersion,

        [Parameter()]
        [switch] $ConfigPackageHash,

        [Parameter()]
        [string] $DataPackageVersion,

        [Parameter()]
        [switch] $DataPackageHash,

        [Parameter()]
        [hashtable] $DiffPackageVersions,

        [Parameter()]
        [ValidateSet('SHA1','SHA256','SHA384')]
        [string] $HashAlgorithm = 'SHA1',

        [Parameter()]
        [string[]] $HashExcludes
    )

    $ErrorActionPreference = 'Stop'
    $versionSeparator = '+'
    $rowFormatString = '{0,-50} {1,-20} -> {2}'

    function HashDirectory([string] $Path)
    {
        $hasher = [Security.Cryptography.HashAlgorithm]::Create($HashAlgorithm)
        foreach ($file in (Get-ChildItem $Path -Recurse -Exclude $HashExcludes -File))
        {
            $buffer = [array]::CreateInstance([byte], 1024)
            $stream = [IO.File]::OpenRead($file.FullName)
            try
            {
                $readCount = 0
                do
                {
                    $readCount = $stream.Read($buffer, 0, $buffer.Length)
                    $tempHash = $hasher.TransformBlock($buffer, 0, $readCount, $null, 0)
                } while ($readCount > 0)
            }
            finally
            {
                $stream.Dispose()
            }
        }

        $tempHash = $hasher.TransformFinalBlock(@(), 0, 0)
        return (New-Object 'System.Numerics.BigInteger' -ArgumentList @(,$hasher.Hash)).ToString('x')
    }

    function GetVersion($Current, $Version)
    {
        $separatorIndex = $Current.IndexOf($versionSeparator)

        if ($separatorIndex -gt 0)
        {
            return $Current.Substring(0, $separatorIndex) + $versionSeparator + $Version
        }
        else
        {
            return $Current + $versionSeparator + $Version
        }
    }

    function UpdatePackageVersion([string] $PackageType, [xml] $ServiceManifest, [string] $Version, [bool] $UseHash)
    {
        $serviceManifestName = $ServiceManifest.ServiceManifest.GetAttribute('Name')

        foreach ($element in $ServiceManifest.GetElementsByTagName($PackageType))
        {
            $packageName = $element.GetAttribute('Name')
            $oldVersion = $element.Version
            $removed = ''

            $innerPackagePath = [IO.Path]::Combine($PackagePath, $serviceManifestName, $packageName)

            if ($UseHash)
            {
                $currentHash = HashDirectory $innerPackagePath
                $Version = $currentHash
            }
            
			if ($Version)
            {
				$newVersion = GetVersion $oldVersion $Version
			}
			else
			{
				$newVersion = $oldVersion
			}

			if ($DiffPackageVersions -ne $null)
            {
                if ($DiffPackageVersions["$serviceManifestName.$packageName.$newVersion"])
                {
                    Remove-item $innerPackagePath -Recurse
                    $removed = '[REMOVED]'
                }
            }

			if ($removed -ne '' -or $newVersion -ne $oldVersion)
			{
				$element.Version = $newVersion
				Write-Output ($rowFormatString -f "    $PackageType $packageName", "    $oldVersion", "    $newVersion $removed")
			}
        }
    }

    $PackagePath = [IO.Path]::Combine((Get-Location), $PackagePath)
    
    $appManifestPath = [IO.Path]::Combine($PackagePath, 'ApplicationManifest.xml')
    if (!(Test-Path $appManifestPath))
    {
        throw "Unable to find the application manifest"
    }

    $appManifest = [xml] (Get-Content $appManifestPath)

    if ($ApplicationVersion -ne $null -and $ApplicationVersion -ne '')
    {
        $oldApplicationVersion = $appManifest.ApplicationManifest.ApplicationTypeVersion
        $newApplicationVersion = GetVersion $oldApplicationVersion $ApplicationVersion
        $appManifest.ApplicationManifest.ApplicationTypeVersion = $newApplicationVersion
        Write-Output ($rowFormatString -f "Application $($appManifest.ApplicationManifest.ApplicationTypeName)", $oldApplicationVersion, $newApplicationVersion)
        Write-Output ''
    }

    if ($DiffPackageVersions -eq $null)
    {
        $DiffPackageVersions = @{}
    }

    $serviceRefList = $appManifest.GetElementsByTagName('ServiceManifestRef')

    foreach ($serviceRef in $serviceRefList)
    {
        $serviceManifestName = $serviceRef.ServiceManifestName
        $serviceManifestPath = [IO.Path]::Combine($PackagePath, $serviceManifestName, 'ServiceManifest.xml')
        if (!(Test-Path $serviceManifestPath))
        {
            throw "Unable to find the service manifest for $serviceManifestName"
        }

        $serviceManifest = [xml] (Get-Content $serviceManifestPath)

        if ($ServiceVersion -ne $null -and $ServiceVersion -ne '')
        {
            $oldServiceVersion = $serviceRef.ServiceManifestVersion
            $newServiceVersion = GetVersion $oldServiceVersion $ServiceVersion
            $serviceRef.ServiceManifestVersion = $newServiceVersion
            $serviceManifest.ServiceManifest.Version = $newServiceVersion
            Write-Output ($rowFormatString -f "  Service $serviceManifestName", "  $oldServiceVersion", "  $newServiceVersion")
        }
        
        UpdatePackageVersion 'CodePackage' $serviceManifest $CodePackageVersion $CodePackageHash
        UpdatePackageVersion 'ConfigPackage' $serviceManifest $ConfigPackageVersion $ConfigPackageHash
        UpdatePackageVersion 'DataPackage' $serviceManifest $DataPackageVersion $DataPackageHash

        Write-Output ''

        $serviceManifest.Save($serviceManifestPath)
    }

    $appManifest.Save($appManifestPath)
}