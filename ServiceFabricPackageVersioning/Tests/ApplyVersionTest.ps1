. "$PSScriptRoot/../Update-ServiceFabricApplicationPackageVersions.ps1"

$path = 'SamplePackagePath'

$PackagePath = [IO.Path]::Combine([IO.Path]::GetTempPath(), (New-Guid))

[IO.Directory]::CreateDirectory($PackagePath)

Copy-Item -Path $path\* -Destination $PackagePath -Recurse

Write-Output "Created a temporary directory $PackagePath"

try
{
    $versions = @{'Stateless1.Config'='1.0.0+47f6209e3b8db5e8c49fb59ea415e0cbd8725070'}

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
