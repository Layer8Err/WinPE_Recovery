## Extract Windows 10 Pro WIM from install.esd included with Windows 10 ISO
# We expect the Windows 10 iso to have been downloaded with the
# Microsoft-provided MediaCreationTool
# Build settings are imported from environment_settings.xml

$adkPEPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs"

Write-Host "----------------------------------------------"
Write-Host "Starting Recovery Environment build process..." -ForegroundColor White
Write-Host "----------------------------------------------"

$localDir = $pwd.Path
$settingsXMLFile = $localDir + '\' + 'environment_settings.xml' # XML file with build settings
$xml = [xml](Get-Content $settingsXMLFile) # Read XML file

$targetOSName = $xml.environment.targetOS #'Windows 10 Pro'
$pathToISO = $localDir + '\Bin\Windows.iso' # Must exist or build will fail
$pathToWIM = $localDir + '\Bin\install.wim' # May not yet exist

$mountInstallTgt = $localDir + '\Mount\install'
$mountWinRETgt = $localDir + '\Mount\winre'
$imageStorageFolder = $localDir + '\Bin'
$driverFolders = $localDir + '\Bin\Drivers'

if ( (Test-Path -Path $mountInstallTgt) -eq $false ){
    mkdir -Path $mountInstallTgt -Force # \Mount\install
}
if ( (Test-Path -Path $mountWinRETgt) -eq $false){
    mkdir -Path $mountWinRETgt -Force # \Mount\winre
}

if ( (Test-Path -Path $pathToISO) -eq $false){
    Write-Host -NoNewline "ERROR: " -ForegroundColor Red
    Write-Host -NoNewline "$pathToISO" -ForegroundColor White
    Write-Host " not found!" -ForegroundColor Red
    Write-Host "Verify that `"Windows.iso`" exists in \Bin" -ForegroundColor Yellow
} else {
    # Custom image target path
    $winRECopy = $imageStorageFolder + '\' + $xml.environment.customWIM  #'\WinreMod.wim'
    $mountRecTools = $mountWinRETgt + '\sources\recovery\tools\'
    ################ If we need the install.wim #################
    if ( (Test-Path $pathToWIM) -eq $false){
        Write-Host "Need to extract Windows image from ISO..."
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
    } else {
        Write-Host "Extracted Windows image found at $pathToWIM!" -ForegroundColor Cyan
    }
    ########################################################
    # Extract Windows Recovery Environment if it hasn't already been extracted
    if (!(Test-Path ($winRECopy))){
        Write-Host -NoNewline "Mounting " -ForegroundColor Cyan
        Write-Host -NoNewLine "$pathToWIM" -ForegroundColor White
        Write-Host " to extract Windows Recovery Environment..." -ForegroundColor Cyan
        DISM /Mount-Wim /WimFile:$pathToWIM /Index:1 /MountDir:$mountInstallTgt
        
        Write-Host -NoNewLine "Copying Windows Recovery Environment to " -ForegroundColor Cyan
        Write-Host "$imageStorageFolder" -ForegroundColor White
        Copy-Item -Path ($mountInstallTgt + '\Windows\System32\Recovery\Winre.wim') -Destination $winRECopy -Force
        Write-Host -NoNewline "Unmounting " -ForegroundColor Cyan
        Write-Host "$pathToWIM" -ForegroundColor White
        DISM /Unmount-Wim /MountDir:$mountInstallTgt /Discard
    } else {
        Write-Host "Founding existing Windows Recovery Environment" -ForegroundColor Green
    }

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
    Write-Host "----------------------------------------------"
    Write-Host "Injecting packages into WinRE..." -ForegroundColor White
    Write-Host "----------------------------------------------"
    Write-Host "Injecting WMI package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-WMI.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-WMI_en-us.cab"
    Write-Host "Injecting NetFX package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-NetFX.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-NetFX_en-us.cab"
    Write-Host "Injecting Scripting package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-Scripting.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-Scripting_en-us.cab"
    Write-Host "Injecting PowerShell package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-PowerShell.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-PowerShell_en-us.cab"
    Write-Host "Injecting StorageWMI package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-StorageWMI.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-StorageWMI_en-us.cab"
    Write-Host "Injecting DISM Cmdlets package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-DismCmdlets.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-DismCmdlets_en-us.cab"
    Write-Host "Injecting Secure Boot package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-SecureBootCmdlets.cab"
    Write-Host "Injecting Secure Startup package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-SecureStartup.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-SecureStartup_en-us.cab"
    Write-Host "Injecting Dot3 service package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-Dot3Svc.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-Dot3Svc_en-us.cab"
    Write-Host "Injecting RNDIS (USB-Ethernet adapter) package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-RNDIS.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-RNDIS_en-us.cab"
    Write-Host "Injecting WDS tools package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-WDS-Tools.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-WDS-Tools_en-us.cab"
    Write-Host "Injecting Win ReCfg package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-WinReCfg.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-WinReCfg_en-us.cab"
    Write-Host "Injecting Enhanced Storage package..." -ForegroundColor Cyan
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\WinPE-EnhancedStorage.cab"
    Dism /Add-Package /Image:$mountWinRETgt /PackagePath:"$adkPEPath\en-us\WinPE-EnhancedStorage_en-us.cab"

    Write-Host "------------------------------------------------------------------" -ForegroundColor White
    Write-Host "Creating file structure for custon Windows Recovery Environment..." -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------------" -ForegroundColor White
    New-Item -Path $mountRecTools -ItemType Directory -Force

    ########################################################
    ## These files may need to be customized with XML settings file before use
    Write-Host "Copying files to tools directory..." -ForegroundColor Cyan
    Copy-Item -Path ( $localDir + '\PEScripts\startRestore.cmd' ) -Destination ( $mountRecTools + '.' ) -Force
    Copy-Item -Path ( $localDir + '\PEScripts\WinRE_RestoreBackup.ps1' ) -Destination ( $mountRecTools + '.' ) -Force

    Write-Host "Reading out partial XML settings for backup share and user..." -ForegroundColor Yellow
    $targetRecXML = $mountRecTools + 'backupsettings.xml'
    $targetxml = [xml]("<environment></environment>")
    $node = $targetxml.SelectSingleNode('//environment')
    function xmlAddAttrib ($node, $attribName, $attribVal) {
        $attrib = $node.OwnerDocument.CreateAttribute($attribName)
        $attrib.Value = $attribVal
        $node.Attributes.Append($attrib)
    }
    xmlAddAttrib -node $node -attribName 'backupuser' -attribVal $xml.environment.backupuser
    xmlAddAttrib -node $node -attribName 'backupusersalt' -attribVal $xml.environment.backupusersalt
    xmlAddAttrib -node $node -attribName 'backupuserpass' -attribVal $xml.environment.backupuserpass
    xmlAddAttrib -node $node -attribName 'backupserver' -attribVal $xml.environment.backupserver
    xmlAddAttrib -node $node -attribName 'backupshare' -attribVal $xml.environment.backupshare
    $targetxml.Save($targetRecXML)

    Write-Host "Over-writing startup INI (winpeshl.ini)..." -ForegroundColor Cyan
    Copy-Item -Path ( $localDir + '\PEScripts\winpeshl.ini' ) -Destination ( $mountWinRETgt + '\Windows\System32\winpeshl.ini' ) -Force

    #Write-Host "WinRE build should be finished. Make any additional modifications and hit <ENTER> to continue." -ForegroundColor Yellow
    #Pause
    ########################################################
    Write-Host "------------------------------------------------------------------" -ForegroundColor White
    Write-Host "Finalizing $winRECopy..." -ForegroundColor Cyan
    DISM /Unmount-Wim /MountDir:$mountWinRETgt /Commit

    Write-Host "...finished building WinPE_Recovery image!" -ForegroundColor Yellow
}
