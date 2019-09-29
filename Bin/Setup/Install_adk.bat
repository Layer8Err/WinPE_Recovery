@ECHO OFF
TITLE Installing Windows ADK
ECHO Installing ADK...
ECHO  * Deployment Tools...
ECHO Please wait, this will take a few minutes
CD "%~dp0"
adksetup.exe /quiet /installpath "C:\Program Files (x86)\Windows Kits\10" /features OptionId.DeploymentTools /norestart
ECHO -------------------------------------------
ECHO Done installing ADK Deployment Tools
PAUSE