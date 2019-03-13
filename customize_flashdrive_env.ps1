# Experimental
# Allows you to customize a flashdrive imaged with the "MediaCreationTool"
# The purpose of this is to allow you to build a flash drive that can install Windows
# or make backups / recoveries
# Copy boot.wim from ESD-USB (H:) > sources to the Bin folder

# Note: This method does NOT work for backups. WBADMIN will not create backups from Windows Recovery Environment

$localDir = $pwd.Path
$recoveryRoot = $localDir
$adkPEPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs"
$pathToBoot = $recoveryRoot + '\Bin\boot.wim' # path to boot.wim copied from flash drive (this is actually the wrong WIM) correct WIM contains setup.exe in ROOT
$mountBootTgt = $recoveryRoot + '\Mount\boot' # path to mount boot.wim
$recoveryScript = $recoveryRoot + '\Prompt_Local_NetworkBackup.ps1' # Path to powershell backup script -- put in X:\sources\

if (!(Test-Path -path $mountBootTgt)){
    Mkdir -Path $mountBootTgt
}

$bootindexes = DISM /Get-WimInfo /WimFile:$pathToBoot
#$peindex = 1 # Name: Microsoft Windows PE (x64) -- try index 2?
$peindex = 2 # We need to use index 2 to modify the recovery environment
DISM /Mount-Wim /WimFile:$pathToBoot /Index:$peindex /MountDir:$mountBootTgt

## Load in PowerShell
Write-Host "----------------------------------------------"
Write-Host "Injecting packages into WinRE..." -ForegroundColor White
Write-Host "----------------------------------------------"
Write-Host "Injecting WMI package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-WMI.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-WMI_en-us.cab"
Write-Host "Injecting NetFX package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-NetFX.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-NetFX_en-us.cab"
Write-Host "Injecting Scripting package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-Scripting.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-Scripting_en-us.cab"
Write-Host "Injecting PowerShell package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-PowerShell.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-PowerShell_en-us.cab"
Write-Host "Injecting StorageWMI package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-StorageWMI.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-StorageWMI_en-us.cab"
Write-Host "Injecting DISM Cmdlets package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-DismCmdlets.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-DismCmdlets_en-us.cab"
Write-Host "Injecting Secure Boot package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-SecureBootCmdlets.cab"
Write-Host "Injecting Secure Startup package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-SecureStartup.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-SecureStartup_en-us.cab"
Write-Host "Injecting Dot3 service package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-Dot3Svc.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-Dot3Svc_en-us.cab"
Write-Host "Injecting RNDIS (USB-Ethernet adapter) package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-RNDIS.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-RNDIS_en-us.cab"
Write-Host "Injecting WDS tools package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-WDS-Tools.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-WDS-Tools_en-us.cab"
Write-Host "Injecting Win ReCfg package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-WinReCfg.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-WinReCfg_en-us.cab"
Write-Host "Injecting Enhanced Storage package..." -ForegroundColor Cyan
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\WinPE-EnhancedStorage.cab"
Dism /Add-Package /Image:$mountBootTgt /PackagePath:"$adkPEPath\en-us\WinPE-EnhancedStorage_en-us.cab"

Write-Host "Copying over local_backup.ps1 script for out-of-band backups..." -ForegroundColor Cyan
Copy-Item -Path $recoveryScript -Destination ($mountBootTgt + "\sources\local_backup.ps1")

Write-Host "Committing changes to boot.wim..." -ForegroundColor Green
DISM /Unmount-Wim /MountDir:$mountBootTgt /Commit
