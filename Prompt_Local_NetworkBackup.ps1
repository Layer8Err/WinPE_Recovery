#Execute
###############################################################################################
# Backup local machine to file share using user input
# Note: This does not work in a Windows Recovery Environment (untested in WinPE)
###############################################################################################

$rmtShare =   Read-Host "UNC Backup Location"
$bakUser =    Read-Host "Backup User"
$credential = Read-Host "Password" -AsSecureString

# Determine if running in a WinPE environment
$wpe = $false
if(Test-Path ($env:WINDIR +"\Systm32\wpeutil.exe")){$wpe = $true}

# Set backupTgt
if (!$wpe){
    $backupTgt = (Get-WmiObject Win32_OperatingSystem).SystemDrive # Local OS drive
} else {
    $backupTgt = 'C:'
}

# Get computername
function Get-ComputerName {
    $pcname = $env:COMPUTERNAME
    if ($wpe){
        $search = (Get-Content -Path ($backupTgt + '\Windows\debug\NetSetup.log') | Select-String "called for computer '")
        if (($search.Length -ge 1) -and ($search.Length -lt 70)){
            $searchline = $search[($search.Length - 1)].ToString()
            $searchlist = $searchline.Split("'")
            $pcname = $searchlist[($searchlist.Length - 2)]
        }

    }
    Return $pcname
}
$pcname = Get-ComputerName

function backupToServer {
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [SecureString]$securestring,
        [Parameter(Position = 2, Mandatory = $true)]
        [String]$backupUser,
        [Parameter(Position = 3, Mandatory = $true)]
        [String]$backupLocation
    )
    # Handle SecureString
    $encryptedstring = $securestring | ConvertFrom-SecureString
    $securepassword = ConvertTo-SecureString $encryptedstring
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepassword)
    $backupPass = [String]([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))
    ## Backup to network
    if ($wpe){
        cmd /c "wpeutil.exe InitializeNetwork"
        WBADMIN START BACKUP -backupTarget:$backupLocation -user:$backupUser -password:$backupPass -include:$backupTgt -allCritical -quiet -noInheritAcl -noVerify
    } else {
        if ((Get-Service -Name NetLogon).Status -ne "Running"){ Start-Service NetLogon }
        WBADMIN START BACKUP -backupTarget:$backupLocation -user:$backupUser -password:$backupPass -include:$backupTgt -allCritical -quiet -noInheritAcl    
    }
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    $backupPass = $null
}


Write-Host "Backing up this PC ($pcname)..." -ForegroundColor Cyan
backupToServer -secureString $credential -backupUser $bakUser -backupLocation $rmtShare