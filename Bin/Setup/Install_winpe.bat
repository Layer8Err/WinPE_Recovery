@ECHO OFF
TITLE Installing Windows PE
ECHO Installing PE...
ECHO Please wait, this will take a few minutes
CD "%~dp0"
adkwinpesetup.exe /Features OptionId.WindowsPreinstallationEnvironment /norestart /quiet /ceip
ECHO -------------------------------------------
ECHO Done installing Windows PE
PAUSE