$cwd = $PWD.Path
Set-Location $cwd
$driverFolder = $cwd + '\Drivers'
if (!(Test-Path $driverFolder)){
    mkdir $driverFolder
}
Write-Host "Beginning Windows Driver export..."
if ($driverFolder -match "FileSystem::"){
    $driverFolder = ( Split-Path -Path $driverFolder -NoQualifier )
}
Export-WindowsDriver -Online -Destination $driverFolder 
