echo 'Copying common modules...'
$tasks = ('ServiceFabricPackageVersioning')
$tasks | % { $path = $_.FullName + '\ps_modules'; echo $path; Copy-Item Common\* $path -Recurse -Force }
 