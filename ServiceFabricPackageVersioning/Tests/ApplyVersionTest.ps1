. "$PSScriptRoot/../Update-ServiceFabricApplicationPackageVersions.ps1"

$path = '.'

$PackagePath = [IO.Path]::Combine([IO.Path]::GetTempPath(), (New-Guid))

[IO.Directory]::CreateDirectory($PackagePath)

Copy-Item -Path $path\* -Destination $PackagePath -Recurse

Write-Output "Created a temporary directory $PackagePath"

try
{
    $versions = @{
		'Stateless1Pkg.Code.1.1.0'=$true;
		'Stateless1Pkg.Code.1.0.0'=$true;
		'Stateless1Pkg.Config.1.0.0'=$true;
	}

    $ApplicationVersion = 'Release-1'
    $ServiceVersion = 'ServiceRelease-1'
    $CodePackageVersion = ''
    $ConfigPackageMode = 'Hash'
    $DataPackageMode = ''

    Update-ServiceFabricApplicationPackageVersions `
        -PackagePath $PackagePath `
        -ApplicationVersion $ApplicationVersion `
        -ServiceVersion $ServiceVersion `
        -CodePackageHash:(($CodePackageMode) -eq 'Hash') `
        -ConfigPackageHash:(($ConfigPackageMode) -eq 'Hash') `
        -DataPackageHash:(($DataPackageMode) -eq 'Hash') `
        -CodePackageVersion $CodePackageVersion `
        -ConfigPackageVersion $ConfigPackageVersion `
        -DataPackageVersion $DataPackageVersion `
        -DiffPackageVersions $versions
}
finally
{
    Remove-Item $PackagePath -Recurse
}
