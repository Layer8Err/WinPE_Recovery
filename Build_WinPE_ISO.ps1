## Create ISO with Windows 10 Recovery Environment custom WIM
# You MUST have Windows 10 ADK installed

Write-Host "Create ISO for network/local recovery"
##### Static Variables Change as needed #####
$localDir = $pwd.Path
$imageStorageFolder = $localDir + '\Bin'
$isoFileLocation = $imageStorageFolder + '\RecoveryPE.iso'
$winPEBuildFolder = $localDir + '\Mount\recoveryiso'
$adkEnvironScript = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
### Read in environment_settings.xml to get customWIM name
$settingsXMLFile = $localDir + '\' + 'environment_settings.xml'
$xml = [xml](Get-Content $settingsXMLFile) # Read XML file
$winRECopy = $imageStorageFolder + '\' + $xml.environment.customWIM
############################################
$winPEbootWIM = $winPEBuildFolder + '\media\sources\boot.wim'
if (Test-Path $winRECopy){
function Invoke-CmdScript {
    param([string]$script, [string]$parameters)
    $tempFile = [IO.Path]::GetTempFileName()
    cmd /c "`"$script`" `"$parameters`" && set > `"$tempFile`""
    Get-Content $tempFile | Foreach-Object {
        if($_ -match "^(.*?)=(.*)$"){
            Set-Content "env:\$($matches[1])" $matches[2]
        }
    }
    Remove-Item $tempFile
}
Write-Host "Setting envorionment variables for ADK..."
Invoke-CmdScript -script $adkEnvironScript
if (Test-Path -Path $winPEBuildFolder){
    Write-Host "Found existing recovery ISO build folder!" -ForegroundColor Red
    Write-Host "Removing build folder and contents..." -ForegroundColor Gray
    Remove-Item -Recurse -Force -Path $winPEBuildFolder
}
if (Test-Path -Path $isoFileLocation){
    Write-Host "Found existing recovery ISO!" -ForegroundColor Red
    Write-Host "Removing existing recovery ISO..." -ForegroundColor Gray

    Remove-Item -Force -Path $isoFileLocation
}
Write-Host -NoNewline "Creating WinPE build files in:" -ForegroundColor Cyan
Write-Host " $winPEBuildFolder" -ForegroundColor White
copype amd64 "$winPEBuildFolder"
Write-Host -NoNewline "Replacing default WinPE image with custom image:" -ForegroundColor Cyan
Write-Host " $winRECopy" -ForegroundColor White
Copy-Item -Path $winRECopy -Destination $winPEbootWIM -Force
Write-Host "Creating ISO with custom image..." -ForegroundColor Yellow

Makewinpemedia /iso "$winPEBuildFolder" "$isoFileLocation"

Write-Host "...Done!" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: $($xml.environment.customWIM) not found!" -ForegroundColor Red
    Write-Host "Maybe you need to run `"Make_WinPE_Recovery.ps1`" first?" -ForegroundColor Yellow
}
