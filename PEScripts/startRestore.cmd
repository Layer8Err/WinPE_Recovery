@ECHO OFF
COLOR 0A
TITLE Network Restore
ECHO Initializing WpeInit...
wpeinit
ECHO Initializing network...
wpeutil initializenetwork
ECHO Enabling PowerShell Script Execution...
powershell -command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Force -Confirm:$false"
ECHO Closing this window will reboot the machine
cd %~dp0
powershell -File WinRE_RestoreBackup.ps1
