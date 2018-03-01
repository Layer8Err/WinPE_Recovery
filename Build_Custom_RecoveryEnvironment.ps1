## Extract Windows 10 Pro WIM from install.esd included with Windows 10 ISO

$targetOSName = 'Windows 10 Pro'
$pathToISO = 'E:\winre\images\InstallCD\Win10.iso'
$pathToWIM = 'E:\winre\images\InstallWims\install.wim' # May not yet exist

$mountInstallTgt = 'E:\winre\mount\install'
$mountWinRETgt = 'E:\winre\mount\winre'
$imageStorageFolder = 'E:\winre\images\'
$driverFolders = 'E:\winre\Drivers'

mkdir -Path $mountInstallTgt -Force
mkdir -Path $mountWinRETgt -Force

$winRECopy = $imageStorageFolder + 'WinreMod.wim'
$mountRecTools = $mountWinRETgt + '\sources\recovery\tools\'
$localDir = $pwd.Path

################ If we need the install.wim #################
if ( (Test-Path $pathToWIM) -eq $false){
    $mountResult = Mount-DiskImage -ImagePath $pathToISO -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    $pathToESD =  $driveLetter + ":\sources\install.esd"

    Write-Host "Checking indexes in $pathToESD" -ForegroundColor Yellow
    $indexes = DISM /Get-WimInfo /WimFile:$pathToESD
    $matcher = 'Name : ' + $targetOSName

    $indexNum = 0
    for ($count = 0; $count -le $indexes.Count ; $count++){
        if ($indexes[$count].Length -gt 0){
            if ($indexes[$count].Trim() -like $matcher) {
                $indexNum = [int](($indexes[($count - 1)]).split(':')[1].Trim())
            }
        }
    }

    if ($indexeNum -ne 0){
        Write-Host "Found $targetOSName at index #$indexNum !" -ForegroundColor Cyan
        Write-Host -NoNewline "Exporting $targetOSName to: " -ForegroundColor Yellow
        Write-Host "$pathToWIM" -ForegroundColor White
        Write-Host "This may take a while..." -ForegroundColor Red
        DISM /export-image /SourceImageFile:$pathToESD /SourceIndex:$indexNum /DestinationImageFile:$pathToWIM /Compress:max /CheckIntegrity
    } else {
        Write-Host "Failed to find $targetOSName in $pathToESD" -ForegroundColor Red
    }
    Write-Host "Unmounting Windows 10 ISO..." -ForegroundColor Cyan
    Dismount-DiskImage -ImagePath $pathToISO
    Start-Sleep -Seconds 5
}
########################################################

Write-Host "Mounting $pathToWIM to extract Windows Recovery Environment..." -ForegroundColor Cyan
DISM /Mount-Wim /WimFile:$pathToWIM /Index:1 /MountDir:$mountInstallTgt

Write-Host "Copying Windows Recovery Environment to $imageStorageFolder" -ForegroundColor Cyan
Copy-Item -Path ($mountInstallTgt + '\Windows\System32\Recovery\Winre.wim') -Destination $winRECopy -Force

Write-Host "Unmounting $pathToWIM ..." -ForegroundColor Cyan
DISM /Unmount-Wim /MountDir:$mountInstallTgt /Discard

Write-Host "Mounting WinRE for customization..." -ForegroundColor Cyan
DISM /Mount-Wim /WimFile:$winRECopy /Index:1 /MountDir:$mountWinRETgt
Start-Sleep -Seconds 10
Write-Host "Injecting Network Drivers into WinRE..." -ForegroundColor Cyan
DISM /Image:$mountWinRETgt /Add-Driver /Driver:$driverFolders /recurse

Write-Host "Setting regional settings to English..." -ForegroundColor Cyan
DISM /Image:$mountWinRETgt /Set-AllIntl:en-US
DISM /Image:$mountWinRETgt /Set-InputLocale:0409:00000409
DISM /Image:$mountWinRETgt /Set-UILang:en-US /Set-SysLocale:en-US
DISM /Image:$mountWinRETgt /Set-UserLocale:en-US
#DISM /Image:$mountWinRETgt /Set-SetupUILang:en-US

## Adjust Time-Zone as needed
Write-Host "Setting Time-zone to EST..." -ForegroundColor Cyan
DISM /Image:$mountWinRETgt /Set-Timezone:"Eastern Standard Time"

Write-Host "Injecting packages into WinRE..." -ForegroundColor Cyan
Write-Host "Injecting WMI package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
Write-Host "Injecting NetFX package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFX.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-NetFX_en-us.cab"
Write-Host "Injecting Scripting package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-Scripting_en-us.cab"
Write-Host "Injecting PowerShell package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-PowerShell_en-us.cab"
Write-Host "Injecting StorageWMI package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"
Write-Host "Injecting DISM Cmdlets package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-DismCmdlets.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-DismCmdlets_en-us.cab"
Write-Host "Injecting Secure Boot package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-SecureBootCmdlets.cab"
Write-Host "Injecting Secure Startup package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-SecureStartup.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-SecureStartup_en-us.cab"
Write-Host "Injecting Dot3 service package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Dot3Svc.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-Dot3Svc_en-us.cab"
Write-Host "Injecting RNDIS (USB-Ethernet adapter) package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-RNDIS.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-RNDIS_en-us.cab"
Write-Host "Injecting WDS tools package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WDS-Tools.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WDS-Tools_en-us.cab"
Write-Host "Injecting Win ReCfg package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WinReCfg.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WinReCfg_en-us.cab"
Write-Host "Injecting Enhanced Storage package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-EnhancedStorage.cab"
Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-EnhancedStorage_en-us.cab"

Write-Host "Creating file structure for custon Windows Recovery Environment..." -ForegroundColor Cyan
New-Item -Path $mountRecTools -ItemType Directory -Force

Write-Host "Copying files to tools directory..." -ForegroundColor Cyan
Copy-Item -Path ( $localDir + '\startRestore.cmd' ) -Destination ( $mountRecTools + '.' ) -Force
Copy-Item -Path ( $localDir + '\WinRE_RestoreBackup.ps1' ) -Destination ( $mountRecTools + '.' ) -Force

Write-Host "Over-writing startup INI (winpeshl.ini)..." -ForegroundColor Cyan
Copy-Item -Path ( $localDir + '\winpeshl.ini' ) -Destination ( $mountWinRETgt + '\Windows\System32\winpeshl.ini' ) -Force

#Write-Host "WinRE build should be finished. Make any additional modifications and hit <ENTER> to continue." -ForegroundColor Yellow
#Pause

Write-Host "Finalizing $winRECopy..." -ForegroundColor Cyan
DISM /Unmount-Wim /MountDir:$mountWinRETgt /Commit

Write-Host "Done" -ForegroundColor Yellow
