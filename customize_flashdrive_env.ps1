# Experimental
# Allows you to customize a flashdrive imaged with the "MediaCreationTool"
# The purpose of this is to allow you to build a flash drive that can install Windows
# or make backups / recoveries
# Copy boot.wim from ESD-USB (H:) > sources to the Bin folder

$pathToBoot = 'C:\winpe_recovery\Bin\boot.wim' # path to boot.wim copied from flash drive
$mountBootTgt = 'C:\winpe_recovery\Mount\boot' # path to mount boot.wim

$bootindexes = DISM /Get-WimInfo /WimFile:$pathToBoot
$peindex = 1 # Name: Microsoft Windows PE (x64)
DISM /Mount-Wim /WimFile:$pathToBoot /Index:$peindex /MountDir:$mountBootTgt

DISM /Unmount-Wim /MountDir:$mountBootTgt /Discard