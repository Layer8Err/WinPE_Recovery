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
# Encryption key (salt)
[Byte[]]$key = (1..16)

$xml = [xml](Get-Content $settingsXMLFile) # Read XML

Clear-Host
Write-Host "Only enter a value if the existing value is wrong."
function changeElement ($element){
    $elementName = $element.Name
    $elementText = $element.'#text'
    # Determine if we need to handle secure string conversion
    if ($elementName -eq "backupuserpass"){
        $newSecureStringYN = Read-Host "Set new encrypted string? [y/N]"
        if ($newSecureStringYN.Substring(0,1).ToLower() -eq 'y'){
            $secureString = Read-Host "Backup User Password" -AsSecureString
            $encryptedString = $secureString | ConvertFrom-SecureString -Key $key
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

foreach ($element in $xml.SelectNodes("//environment/*")){
    changeElement($element)
}
$xml.Save($settingsXMLFile)