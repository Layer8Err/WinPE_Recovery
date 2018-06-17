####################################################
# Modify settings to match your environment
#
# This tool will edit the environment_settings.xml
# file to match your environment.
####################################################
# Get path to environment_settings.xml
Set-Location $PSScriptRoot
$localDir = $pwd.Path
$settingsXMLFile = $localDir + '\' + 'environment_settings.xml'
####################################################
## Helper functions
# Generate a random string to be used when salting the password
function makeSaltString (){
    $keysize = 32 # Length of salt
    $keybits = @()
    for ($i = 1; $i -le $keysize; ++$i){
        $keybits += (Get-Random -Minimum 1 -Maximum 99 -SetSeed (Get-Random -Minimum 50 -Maximum 100))
    }
    $keybitstring = "" # String with keybits
    $keybits | ForEach-Object {
        $keybitstring += ([String]$_ + ',')
    }
    $keybitstring = $keybitstring.Substring(0, ($keybitstring.Length - 1)) # Trim trailing comma
    return $keybitstring
}

# Convert string into byte list
function stringToBytes ($keybitstring){
    # We expect $keybitstring to be a single comma-seperated string with no spaces
    $bitsplits = $keybitstring.Split(',') # Convert string back into list
    $bitsplitn = @() # List to hold integers
    $bitsplits | ForEach-Object { $bitsplitn += [Int32]$_ } # Convert strings into Int32
    [Byte[]]$key = $bitsplitn
    return [Byte[]]$key
}

# Handle XML element changes
function changeElement ($element){
    $elementName = $element.Name
    $elementText = $element.'#text'
    # Determine if we need to store a new salt
    if ($elementName -eq "backupusersalt") {
        if (($xml.environment.($element.Name)).Length -lt 8){
            Write-Host "No valid key string detected. Auto-generating a random key..." -ForegroundColor Red
            $xml.environment.($element.Name) = makeSaltString
        } else {
            Write-Host "Found existing password salt" -ForegroundColor Yellow
            $usenewSaltYN = Read-Host "Use new password salt? [y/N]"
            if ($usenewSaltYN.Substring(0,1).ToLower() -eq 'y'){
                $xml.environment.($element.Name) = makeSaltString
            }
        }
    } 
    # Determine if we need to handle secure string conversion with salt
    elseif ($elementName -eq "backupuserpass") {
        Write-Host "Create new password?"
        $newSecureStringYN = Read-Host "Set new encrypted string? [y/N]"
        if ($newSecureStringYN.Substring(0,1).ToLower() -eq 'y'){
            $secureString = Read-Host "Backup User Password" -AsSecureString
            #$encryptedString = $secureString | ConvertFrom-SecureString -Key $key
            $encryptedString = $secureString | ConvertFrom-SecureString -Key (stringToBytes($xml.environment.backupusersalt))
            $xml.environment.($element.Name) = [String]$encryptedString
        }
    } else {
        Write-Host "Value for $elementName is $elementText"
        $newValue = Read-Host "New value"
        if (!(!$newValue)){
            $xml.environment.($element.Name) = [String]$newValue
        }
    }
}

Clear-Host
Write-Host "Only enter a value if the existing value is wrong."
$xml = [xml](Get-Content $settingsXMLFile) # Read XML
foreach ($element in $xml.SelectNodes("//environment/*")){
    changeElement($element)
}
$xml.Save($settingsXMLFile)
Write-Host "...Done!" -ForegroundColor Yellow
