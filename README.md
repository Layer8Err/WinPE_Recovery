# WinPE_Recovery

Build a Windows 10 recovery environment with support for network-based image recovery.

These scripts have been tested with:
* Windows 10 Pro (x64) build 16299 and Windows ADK 1709.
* Windows 10 Pro (x64) build 17134 and Windows ADK 1803.

## Requirements

### Windows ADK

You must have Windows ADK installed in order to generate a custom recovery environment.

You can download Windows ADK from Microsoft's website: 
https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install

Make sure to install the same ADK version as your target Windows version

### Windows 10 ISO

This script expects a Windows 10 ISO downloaded via the Windows Media creation tool.
The resulting ISO file does not contain install.wim, and instead contains install.esd.

You can download the Windows 10 Media creation tool from Microsoft's website: 
https://www.microsoft.com/en-us/software-download/windows10

When you run the Media creation tool, you will be creating "installation media for another PC"
and selecting the "ISO file" option.

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

You will want to customize ```Make_WinPE_Recovery.ps1``` as needed before
generating your custom WinPE image file. 

Current defaults are:
* Language: EN-US
* Time Zone: Eastern Standard Time

You will also want to customize any additional sciprts as needed:
* Customize the ```PEScripts\WinRE_RestoreBackup.ps1``` file as needed
* Customzie the ```Create_NetworkBackup.ps1``` file as needed

## Building your custom WinPE Image

Once your build environment has been prepared it is time to generate your custom
Windows 10 recovery image.

Run the ```Make_WinPE_Recovery.ps1``` script to create a custom recovery image:

```
PS C:\WinPE_Recovery> .\Make_WinPE_Recovery.ps1
```

* Default recovery image name: is "__WinreMod.wim__"
* Recovery image is stored in the "__Bin__" folder

## Using your custom WinPE Image

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
Make sure that your flash drive is properly formatted before you attemt to image it.

### WDS/MDT/SCCM

You can use the recovery image with Windows Deployment Services and Microsoft Deployment tools or SCCM to allow computers to boot
into your customized recovery environment via network boot (PXE).
