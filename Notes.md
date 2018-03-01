
Save PowerShell script under Tools:
cp WinRE_RestoreBackup.ps1 $mountdir\sources\recovery\tools\.

Edit launch entry in $mountdir\Windows\System32\winpeshl.ini

For syntax on winpeshl.ini:
https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpeshlini-reference-launching-an-app-when-winpe-starts

[For orphaned mount points]
DISM /Cleanup-Mountpoints # Deletes all resources associated with a mounted image that has been corrupted.
DISM /Cleanup-WIM
DISM /UNMOUNT /DISCARD

