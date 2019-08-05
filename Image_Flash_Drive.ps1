## Image flash drive with Windows 10 Recovery Environment custom WIM
# You MUST have Windows 10 ADK installed

Write-Host "Image Flash Drive for network/local recovery"
##### Static Variables Change as needed #####
$localDir = $pwd.Path
$flashDriveLetter = 'F'
$flashDriveLetter = Read-Host "Flash Drive Letter (e.g. `"F`")"
$imageStorageFolder = $localDir + '\Bin'
$winPEBuildFolder = $localDir + '\Mount\recoverymedia'
$adkEnvironScript = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
### Read in environment_settings.xml to get customWIM name
$settingsXMLFile = $localDir + '\' + 'environment_settings.xml'
$xml = [xml](Get-Content $settingsXMLFile) # Read XML file
$winRECopy = $imageStorageFolder + '\' + $xml.environment.customWIM
############################################
$winPEbootWIM = $winPEBuildFolder + '\media\sources\boot.wim'
$flashDriveLetter += ':'

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

Write-Host "Creating WinPE build files in $winPEBuildFolder" -ForegroundColor Cyan
copype amd64 "$winPEBuildFolder"
Write-Host "Replacing default WinPE image with custom image $winRECopy" -ForegroundColor Cyan
Copy-Item -Path $winRECopy -Destination $winPEbootWIM -Force
Write-Host "Imaging flash drive with custom WIM..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

## Manually set up boot options for flash drive using exFat instead of FAT32 (semi-tested)
## exFAT allows for larger flash-drives to be used.
## FAT32 is REQUIRED if BIOS/UEFI boot methods both need to be supported.
# # DiskPart params
# $tempFile = [IO.Path]::GetTempFileName()
# # CLEAN
# # CONVERT MBR ## Convert to MBR partition scheme for BIOS or UEFI
# # CREATE PARTITION PRIMARY
# # SELECT PARTITION 1
# $imageCmds = "SELECT VOLUME=$flashDriveLetter`nFORMAT fs=exFAT quick label=`"WinPE`"`nACTIVE"
# Write-Output $imageCmds >> $tempFile
# Write-Host "Formatting $flashDriveLetter..."
# diskpart /s $tempFile
# Write-Host "Setting boot code on $flashDriveLetter..."
# bootsect.exe /nt60 $flashDriveLetter /force /mbr
# Write-Host "Setting up UEFI boot data on $flashDriveLetter..."
# $bootdata="2#p0,e,b`"$winPEBuildFolder\fwfiles\etfsboot.com`"#pEF,e,b`"$winPEBuildFolder\fwfiles\efisys.bin`""
## oscdimg will probably fail, and is probably not needed for flash drive boot
# oscdimg -bootdata:$bootdata -u1 -udfver102 "$winPEBuildFolder\media" "$flashDriveLetter"

MakeWinPEMedia /ufd /f "$winPEBuildFolder" $flashDriveLetter
Write-Host "Over-writing in the (likely) event that MakeWinPEMedia partially failed." -ForegroundColor Cyan
xcopy ($winPEBuildFolder + "\media\*.*") /s /e /f /y ($flashDriveLetter + "\")

Write-Host "Adding `"CreateBackup`" folder to flash drive for creating backups..." -ForegroundColor Cyan
mkdir -Path ($flashDriveLetter + "\CreateBackup")
Copy-Item -Path $settingsXMLFile -Destination ($flashDriveLetter + "\CreateBackup\environment_settings.xml")
Copy-Item -Path ($localDir + "\Local_NetworkBackup.ps1") -Destination ($flashDriveLetter + "\CreateBackup\Local_NetworkBackup.ps1")
Copy-Item -Path ($localDir + "\Bin\CreateBackup\StartBackup.bat") -Destination ($flashDriveLetter + "\CreateBackup\StartBackup.bat")

Write-Host "...Done!" -ForegroundColor Yellow
