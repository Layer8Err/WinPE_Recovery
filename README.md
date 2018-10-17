# WinPE_Recovery

Build a Windows 10 recovery environment with support for network-based image recovery.

These scripts have been tested with:
* Windows 10 Pro (x64) build 16299 and Windows ADK 1709.
* Windows 10 Pro (x64) build 17134 and Windows ADK 1803.
* Windows 10 Pro (x64) build 17763 and Windows ADK 1809.

## Requirements

### Windows ADK

You must have Windows ADK installed in order to generate a custom recovery environment.

You can download Windows ADK from Microsoft's website: 
https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install

Make sure to install the same ADK version as your target Windows version

You will need to install ADK with:
* Deployment Tools (DISM)
* Windows Preinstallation Environment (if pre 1809)
```
PS C:\WinPE_Recovery\Bin> .\adksetup.exe /Features OptionId.DeploymentTools /norestart /quiet /ceip off
```

### Windows PE

As of Windows 10 (1809) the Windows Preinstallation Environment (PE) is released separately from the Assessment and Deployment Kit (ADK).

You can download the Windows PE add-on for the ADK from Microsoft's website:
https://go.microsoft.com/fwlink/?linkid=2022233

```
PS C:\WinPE_Recovery\Bin> .\adkwinpesetup.exe /Features OptionId.WindowsPreinstallationEnvironment /norestart /quiet /ceip off
```

### Windows 10 ISO

This script expects a Windows 10 ISO downloaded via the Windows Media creation tool.
The resulting ISO file does not contain install.wim, and instead contains install.esd.

You can download the Windows 10 Media creation tool from Microsoft's website: 
https://www.microsoft.com/en-us/software-download/windows10

When you run the Media creation tool, you will be creating "installation media for another PC"
and selecting the "ISO file" option.

### Backup file share

You should already have a network file-share intended to store backup images.
You will need credentials to connect to the file-share. It is recommended that you test the
connection to your backup file share before you configure your environment settings.

The ```netlogon``` service must be running on your backup file server.

## Preparing your build environment

Once you have Windows ADK installed and a Windows 10 ISO downloaded, move the ISO to the
"__Bin__" folder.

### Configuring Environment Settings

Before generating a custom WinPE recovery image, you will need to generate valid environment
settings. The environment settings are stored in ```environment_settings.xml``` for use in
other scripts.

In order to configure your environment settings, run:
```
PS C:\WinPE_Recovery> .\Configure.ps1
```

### Preparing Drivers

When the custom WinPE image is created, drivers located in ```Bin\Drivers\``` will be
injected into the final WinPE image. If you need to support any non-standard network or
storage interfaces, you can place uncompressed driver files into this folder.

### Additional Configuration

You may want to customize ```Make_WinPE_Recovery.ps1``` as needed before
generating your custom WinPE image file. 

Current defaults are:
* Language: EN-US
* Time Zone: Eastern Standard Time

Settings defined in ```environment_settings.xml``` will be used by these files:
* ```PEScripts\WinRE_RestoreBackup.ps1```
* ```Remote_NetworkBackup.ps1```

## Building your custom WinPE Image

Once your build environment has been prepared it is time to generate your custom
Windows 10 recovery image.

Run the ```Make_WinPE_Recovery.ps1``` script to create a custom recovery image:

```
PS C:\WinPE_Recovery> .\Make_WinPE_Recovery.ps1
```

* Default recovery image name: is "__WinreMod.wim__"
* Recovery image is stored in the "__Bin__" folder

## Creating a backup image

You can use ```Remote_NetworkBackup.ps1``` to create a backup image of a remote PC
on the backup share defined in ```environment_settings.xml```.
This script uses WinRM to create a backup job on the remote PC.
Backups are created using ```WBADMIN``` which uses VSS to create a snapshot of the drive.
Because these backups are selective, differential backups, they are not intended for
forensic use. These block-level backups are intended to be used for fast backups and quick
recoveries.

You can use ```Get-Job``` from the PowerShell terminal to list the status of the backup job. If jobs are completing very
quickly, you may want to verify that your settings are correct.

_Because remote backups are made when a PC is booted into Windows, the backup image is not
encrypted with BitLocker even if the PC being backed up is encrypted._

## Booting your custom WinPE Image

### Creating Recovery ISO

Once the recovery image (e.g. ```WinreMod.wim```) has been created you can use it to create a bootable ISO.
```
PS C:\WinPE_Recovery> .\Build_WinPE_ISO.ps1
```
By default, the recovery ISO is named "__RecoveryPE.iso__" and is stored in the "__Bin__" folder.
You can use your bootable ISO with a virtual machine to test your environment settings and customizations.

### Creating Recovery Flash Drive

Once the recovery image has been created you can use it to create recovery flash drive:
```
PS C:\WinPE_Recovery> .\Image_Flash_Drive.ps1
```
Make sure that your flash drive is properly formatted before you attempt to image it.

### WDS/MDT/SCCM

You can use the recovery image with Windows Deployment Services and Microsoft Deployment tools or SCCM to allow computers to boot
into your customized recovery environment via network boot (PXE).

## Restoring an image

_"If you haven't tested your backups, you don't have any backups." ~ Anon_

### From locally attached storage

Once you have booted into your Windows PE Recovery environment, allow the automated network script to launch
the "generic recovery tools GUI".
The Windows PE Recovery Environment has a GUI for recovering from locally attached storage.

1. From the Windows Recovery Environment select your keyboard layout
2. Select "Troubleshoot"
3. Select "System Image Recovery"
4. Choose your target operating system to recover
5. Make sure that your external recovery drive is attached
6. Select the backup you want to use
7. Click "Next" to begin the restore process

### From network share

As long as your backup is stored in the network share defined in your ```environment_settings.xml``` file it should
automatically be detected when you boot into your Custom Windows PE Recovery Environment.

1. Select which backup you want to restore from (e.g. type "1" and hit "ENTER")
2. You will be prompted to confirm that you want to continue with the image restore. Hit "y" and "ENTER" to continue.
3. If the drive is encrypted with BitLocker, you will need to enter the BitLocker recovery key. __The drive will no longer be encrypted after the recovery process__.
4. ```WBADMIN``` will begin the recovery operation.
5. When the recovery operation is complete, the PC will reboot.
