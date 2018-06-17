#Execute
###############################################################################################
# Backup a machine remotely using environment_settings.xml
#
# WinRM must be enabled on the remote machine
###############################################################################################

### Read in environment_settings.xml to get Domain and Admin info
$localDir = $pwd.Path
$settingsXMLFile = $localDir + '\' + 'environment_settings.xml'
$xml = [xml](Get-Content $settingsXMLFile) # Read XML file
$adminName = $xml.environment.domain + '\' + $xml.environment.domainadmin
# Allow authentication
if ($cred) {} else { $cred = Get-Credential $adminName }

function stringToBytes ($keybitstring){
    # We expect $keybitstring to be a single comma-seperated string with no spaces
    $bitsplits = $keybitstring.Split(',') # Convert string back into list
    $bitsplitn = @() # List to hold integers
    $bitsplits | ForEach-Object { $bitsplitn += [Int32]$_ } # Convert strings into Int32
    [Byte[]]$key = $bitsplitn
    return [Byte[]]$key
}

[Byte[]]$bakkey = stringToBytes $xml.environment.backupusersalt # get encryption key from XML settings file
$cryptedPass = $xml.environment.backupuserpass # get encryption key from XML settings file
$rmtShare = '\\' + $xml.environment.backupserver + '\' + $xml.environment.backupshare
$bakUser = $xml.environment.backupuser

$backupBlock = [ScriptBlock]::Create({
    function backupToServer {
        [CmdletBinding()] Param(
            [Parameter(Position = 0, Mandatory = $true)]
            [String]$cryptedPass
        )
        $backupTgt = (Get-WmiObject Win32_OperatingSystem).SystemDrive # Local OS drive
        $remoteShare = $rmtShare
        $backupUser = $bakUser
        ## Handle encrypted password
        [Byte[]]$key = $bakkey # Same 16 bit encryption key
        $encryptPass1 = [String]$cryptedPass | ConvertTo-SecureString -Key $key # Decrypt with key
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptPass1) # rotate into store
        $backupPass = [String]([System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)) # get string value
        ## Backup to network
        WBADMIN START BACKUP -backupTarget:$remoteShare -user:$backupUser -password:$backupPass -include:$backupTgt -allCritical -quiet -noInheritAcl
    }
})
$encryptPass1 = [String]$cryptedPass | ConvertTo-SecureString -Key $bakkey
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
