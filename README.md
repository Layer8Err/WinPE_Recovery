# WinPE_Recovery
Build a Windows 10 recovery environment with support for network-based image recovery.

These scripts have been tested with Windows 10 Pro (x64) build 16299 and Windows ADK 1709.

## Requirements
### Windows ADK
You must have Windows ADK installed in order to generate a custom recovery environment.
You can download Windows ADK from Microsoft's website:
> https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install

Make sure to install the same ADK version as your target Windows version
### Windows 10 ISO
This script expects a Windows 10 ISO downloaded via the Windows Media creation tool.
The resulting ISO file does not contain install.wim, and instead contains install.esd.
You can download the Windows 10 Media creation tool from Microsoft's website:
> https://www.microsoft.com/en-us/software-download/windows10

When you run the Media creation tool, you will be creating "installation media for another PC"
and selecting the "ISO file" option.

## Usage
Once you have Windows ADK installed and a Windows 10 ISO downloaded, move the ISO to the
WinPE_Recovery folder.
Customize the Build_Custom_RecoveryEnvironment.ps1 file as needed

Current defaults are:
> Language: EN-US
> Time Zone: Eastern Standard Time

Customize the WinRE_RestoreBackup.ps1 file as needed
Customzie the Create_NetworkBackup.ps1 file as needed

Run the Build_Custom_RecoveryEnvironment.ps1 script to create a custom recovery image.

Default recovery image name:
> WinreMod.wim

Once the recovery image has been created you can use it to create recovery flash drive:
> PS C:\WinPE_Recovery\ .\Image_Flash_Drive.ps1

_Or_ you can use it with Windows Deployment Services to create a Network Bootable
recovery environment.
