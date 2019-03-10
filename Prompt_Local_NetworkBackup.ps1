#Execute
###############################################################################################
# Backup local machine to file share using user input
#
###############################################################################################

$rmtShare =   Read-Host "UNC Backup Location"
$bakUser =    Read-Host "Backup User"
$credential = Read-Host "Password" -AsSecureString

function backupToServer {
    [CmdletBinding()] Param(
        [Parameter(Position = 0, Mandatory = $true)]
        [SecureString]$securestring,
        [Parameter(Position = 2, Mandatory = $true)]
        [String]$backupUser,
        [Parameter(Position = 3, Mandatory = $true)]
        [String]$backupLocation
    )
    $backupTgt = (Get-WmiObject Win32_OperatingSystem).SystemDrive # Local OS drive
    # Handle SecureString
    $encryptedstring = $securestring | ConvertFrom-SecureString
    $securepassword = ConvertTo-SecureString $encryptedstring
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepassword)
    $backupPass = [String]([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR))
    ## Verify local NetLogon service is running and start if it is not
    if ((Get-Service -Name NetLogon).Status -ne "Running"){ Start-Service NetLogon }
    ## Backup to network
    WBADMIN START BACKUP -backupTarget:$backupLocation -user:$backupUser -password:$backupPass -include:$backupTgt -allCritical -quiet -noInheritAcl
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    $backupPass = $null
}
Write-Host "Backing up this PC ($env:COMPUTERNAME)..." -ForegroundColor Cyan
backupToServer -secureString $credential -backupUser $bakUser -backupLocation $rmtShare