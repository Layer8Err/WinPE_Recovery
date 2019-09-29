# Helper script to bootstrap the image restore process
# WinRE will need to have the appropriate network drivers and PowerShell
# components injected

# Read in settings from backupsettings.xml
Set-Location -Path $PSScriptRoot
$localDir = $pwd.Path
$settingsXMLFile = $localDir + '\' + 'backupsettings.xml' # XML file with build settings
$xml = [xml](Get-Content $settingsXMLFile)

# Authentication and path variables
$remoteShare = '\\' + $xml.environment.backupserver + '\' + $xml.environment.backupshare
$backupUser = $xml.environment.backupuser

function stringToBytes ($keybitstring){
    # We expect $keybitstring to be a single comma-seperated string with no spaces
    $bitsplits = $keybitstring.Split(',') # Convert string back into list
    $bitsplitn = @() # List to hold integers
    $bitsplits | ForEach-Object { $bitsplitn += [Int32]$_ } # Convert strings into Int32
    [Byte[]]$key = $bitsplitn
    return [Byte[]]$key
}
[Byte[]]$key = stringToBytes $xml.environment.backupusersalt
$encryptPass1 = [String]$xml.environment.backupuserpass | ConvertTo-SecureString -Key $key
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptPass1)
# Get decoded passcode
$backupPass = [String]([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))
# Get SystemEnclosure Serial Number (used to identify which PC to recover an image for)
Write-Host "Getting Asset Tag for this PC..." -ForegroundColor Yellow
$assetTag = (Get-WmiObject Win32_SystemEnclosure).SerialNumber.Trim()
Write-Host "Asset Tag: $assetTag"
$useDetectedAssetTag = Read-Host "Use detected Asset Tag as Computer Name? [Y/n]"
if ($useDetectedAssetTag.Substring(0,1).ToLower() -eq 'n') {
    $assetTag = Read-Host "Computer Name"
}
# Authenticate with remote share
Write-Host "Establishing connection with backup share $remoteShare ..." -ForegroundColor Yellow
$shareSrv = $remoteShare.Split("\")[2]
ping -n 4 $shareSrv
#Write-Host $remoteShare -ForegroundColor Green
#Write-Host $backupUser -ForegroundColor Green
Start-Sleep -Seconds 5
net use Z: $remoteShare /User:$backupUser $backupPass
# Grab the backup versions for this machine
Write-Host "Requesting backup versions for $assetTag..."
Write-Host "`n"
$backupVersions = wbadmin get versions -backuptarget:$remoteShare -machine:$assetTag
$backupIDs = @()
$backupVersions | ForEach-Object {
    if ( $_ -match 'Version identifier' ){
        $thisIDarr = $_.Trim().split(':')
        $thisID = $thisIDarr[1].Trim() + ':' + $thisIDarr[2].Trim()
        $backupIDs += $thisID
    }
}

function recoveryEnvGui {
    Start-Process 'X:\sources\recovery\RecEnv.exe'
}

function findPartitions {
    # This assumes network boot and single hard-drive
    $partsinfo = Write-Output "SELECT DISK 0`nLIST PARTITION" | diskpart.exe
    $partsfound = $true
    $partsinfo | ForEach-Object {
        if ($_ -match "There are no partitions on this disk to show."){
            $partsfound = $false
        }
    }
    return $partsfound
}

function getBitlockerinfo {
    # Return bitlockerinfo on locked drive. We are only looking for the 'C:' drive if there are multiple drives
    $bitlockerinfo = ( Get-WmiObject -Class Win32_EncryptableVolume -Namespace root/cimv2/Security/MicrosoftVolumeEncryption )
    if ($bitlockerinfo.Length -ge 2){
        $bitlockerinfo | ForEach-Object {
            if ($_.DriveLetter -match 'C:'){
                $bitlockerinfo = $_
            }
        }
    }
    return $bitlockerinfo
}

function isBitlocked {
    # Function to check if the drive is encrypted with BitLocker (Could also use manage-bde -status | SLS "Lock Status")
    $bitlocked = $false
    $bitlockerinfo = getBitlockerinfo
    if ($bitlockerinfo.ProtectionStatus -gt 0){
        $bitlocked = $true
    }
    return $bitlocked
}

function unlockBitlocker {
    # Use BitLocker to unlock drive C: it will still be unlocked after reboot
    Write-Host "Please enter the BitLocker Recovery Key (e.g. 123321-456654-789987-987789-654456-321123-147963)"
    [String]$blpass = Read-Host ">"
    manage-bde -unlock C: -RecoveryPassword $blpass
}

function recoverBackup {
    [CmdletBinding()] Param(
    [Parameter(Position = 0, Mandatory = $True)]
    [String]$bakID,
    [Parameter(Position = 1, Mandatory = $True)]
    [String]$remoteShare
    )
    Write-Host "=============Starting recovery=============" -ForegroundColor Yellow
    Write-Host " Remote Share: $remoteShare"
    Write-Host " Asset Tag:    $assetTag"
    Write-Host " Backup:       $bakID"
    Write-Host "===========================================" -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    if (isBitlocked){
        Write-Host "C: drive is encrypted with BitLocker" -ForegroundColor Red
        unlockBitlocker
    }
    Start-Sleep -Seconds 3
    if ( findPartitions ){
        Write-Host "Recovering to existing partitions..." -ForegroundColor Cyan
        wbadmin start sysrecovery -version:$bakID -backuptarget:$remoteShare -machine:$assetTag -quiet
    } else {
        Write-Host "Recovering and RECREATING disk partitions..." -ForegroundColor Yellow
        wbadmin start sysrecovery -version:$bakID -backuptarget:$remoteShare -machine:$assetTag -recreateDisks -restoreAllVolumes -quiet
    }
    # Reboot when finished with image recovery
    Write-Host "Press ENTER to reboot" -ForegroundColor Red
    pause
    Write-Host "Rebooting $assetTag..." -ForegroundColor Red
    Start-Sleep -Seconds 10
    wpeutil reboot
}

function backupMenu {
    if ($backupIDs.Count -gt 0){
        $index = 0
        Start-Sleep -Seconds 3
        Clear-Host
        Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
        Write-Host -NoNewline "|" -ForegroundColor Cyan
        Write-Host -NoNewline "          NETWORK IMAGE RECOVERY         " -ForegroundColor White -BackgroundColor DarkBlue
        Write-Host "|" -ForegroundColor Cyan
        Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
        Write-Host "===========Select Recovery Image===========" -ForegroundColor Cyan
        $backupIDs | ForEach-Object {
            ++$index
            Write-Host "$index`t$_"
        }
        $latestBakID = $backupIDs[($backupIDs.Count - 1)]
        Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
        Write-Host "|    Type 'exit' to launch Recovery GUI   |" -ForegroundColor Yellow
        Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
        $backupOK = $false
        try {
            [INT]$choice = Read-Host ">"
            if (($choice -ne "") -and ($choice -ge 1) -and ($choice -le $index)){
                $chosenID = $backupIDs[$choice - 1]
                [String]$begin = Read-Host "Ready to begin image restore? [y/N]"
                if ( ($begin.Trim().Substring(0,1).ToLower()) -eq 'y' ){
                    $backupOK = $true
                }
            } else {
                Write-Host "Invalid selection" -ForegroundColor Red
                backupMenu
            }
        } catch {
            $backupOK = $false
            Write-Host "No backup selected" -ForegroundColor Red
        }
        if ($backupOK){
            recoverBackup -bakID $chosenID -remoteShare $remoteShare
        } else {
            Clear-Host
            Write-Host "Not attempting network recovery..." -ForegroundColor Yellow
            cmd /c '%SYSTEMROOT%\System32\startnet.cmd'
            Write-Host "Launching generic recovery tools GUI..." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            recoveryEnvGui
            Write-Host "Pressing <ENTER> will reboot the PC" -ForegroundColor Red
            Pause
        }
    } else {
        Write-Host "No recovery images found on $remoteShare" -ForegroundColor Red
        Write-Host "for this PC: $assetTag" -ForegroundColor Red
        cmd /c '%SYSTEMROOT%\System32\startnet.cmd'
        Write-Host "Launching generic recovery tools GUI..." -ForegroundColor Cyan
        Start-Sleep -Seconds 4
        recoveryEnvGui
        Write-Host "Pressing <ENTER> will reboot the PC" -ForegroundColor Red
        Pause
    }
}

backupMenu
