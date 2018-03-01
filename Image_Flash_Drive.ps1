## Image flash drive with Windows 10 Recovery Environment custom WIM
# You MUST have Windows 10 ADK installed

##### Static Variables Change as needed #####
$flashDriveLetter = 'F'
$imageStorageFolder = 'E:\winre\images\'
$winRECopy = $imageStorageFolder + 'WinreMod.wim'
$winPEBuildFolder = 'E:\winre\recoverymedia'
$adkEnvironScript = 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat'
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
Write-Host "Done" -ForegroundColor Yellow
