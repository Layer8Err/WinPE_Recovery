@ECHO OFF
TITLE Backing up Windows Drivers
ECHO Backing up Windows Drivers...
COLOR 0A
CD "%~dp0"
powershell .\BackupDrivers.ps1
ECHO ----------------------------------------------------
ECHO Done backing up drivers.
PAUSE