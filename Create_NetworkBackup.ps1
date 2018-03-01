#Execute
###############################################################################################
# Backup a machine remotely
#
# This PowerShell script has been tested with PowerShell 5.0 on Windows 10.
# This PowerShell script has been tested with PowerShell 5.0 on Windows 7.
###############################################################################################

# Allow authentication
$adminName = 'DOMAIN\adminuser'
if ($cred) {} else { $cred = Get-Credential $adminName }

[Byte[]]$key = (1..16) # 16 bit encryption key
$cryptedPass = 'Long enrypted string' # Modify this or prompt for the password and encode

$backupBlock = [ScriptBlock]::Create({
    function backupToServer {
        [CmdletBinding()] Param(
            [Parameter(Position = 0, Mandatory = $true)]
            [String]$cryptedPass
        )
        $backupTgt = (Get-WmiObject Win32_OperatingSystem).SystemDrive # Local OS drive
        $remoteShare = '\\SERVER\RemoteShare'
        $backupUser = 'backupuser'
        ## Handle encrypted password
        [Byte[]]$key = (1..16) # Same 16 bit encryption key
        $encryptPass1 = [String]$cryptedPass | ConvertTo-SecureString -Key $key # Decrypt with key
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptPass1) # rotate into store
        $backupPass = [String]([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)) # get string value
        ## Backup to network
        WBADMIN START BACKUP -backupTarget:$remoteShare -user:$backupUser -password:$backupPass -include:$backupTgt -allCritical -quiet -noInheritAcl
    }
})
$encryptPass1 = [String]$cryptedPass | ConvertTo-SecureString -Key $key
$backupBlock2 = [ScriptBlock]::Create($backupBlock.ToString() + "backupToServer -cryptedPass $cryptedPass")

$pcname = Read-Host "Computer to back up"
Invoke-Command -ComputerName $pcname -Credential $cred -ScriptBlock $backupBlock2 -AsJob -JobName ($pcname + '_backup')

## Password encryption/decryption method
# $backupPass2 = 'plaintextpassword' | ConvertTo-SecureString -AsPlainText -Force
# $encryptPass2 = $backupPass2 | ConvertFrom-SecureString -key $key
# $encryptPass2 = $encryptPass3 = ''Long enrypted string' # Modify this or prompt for the password and encode
# $encryptPass4 = [String]$encryptPass3 | ConvertTo-SecureString -Key $key

# $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptPass4)
# $cleartextpass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
