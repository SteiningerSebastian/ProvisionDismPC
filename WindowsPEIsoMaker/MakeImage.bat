:: Author: Sebastian Steininger (sebastian.steininger@outlook.com)

@echo off

:: BatchGotAdmin Author: Eneerge @ https://sites.google.com/site/eneerge/scripts/batchgotadmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------   

:: Remember where the file is placed.
SET start_directory=%~dp0
SET start_directory=%start_directory:~0,-1%

echo Building the WinPE_amd64.iso file ...

:: If the folder does not exist init the winPe direcotry.
if not exist %start_directory%\WinPE_amd64_PS call %start_directory%\InitWinPe.bat

:: Mount the image to the directory for customization.
if not exist %start_directory%\WinPE_amd64_PS\mount\Windows\System32\startnet.cmd call %start_directory%\Mount.bat

:: --------------------------------------   Customize the image --------------------------------------   

echo Customizing image ...

Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFX.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-NetFX_en-us.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-Scripting_en-us.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-PowerShell_en-us.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-DismCmdlets.cab"
Dism /Add-Package /Image:"%start_directory%\WinPE_amd64_PS\mount" /PackagePath:"%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-DismCmdlets_en-us.cab

::Copy the ps1 script to the correct location
copy /Y %start_directory%\DeployCapture.ps1 %start_directory%\WinPE_amd64_PS\mount\Windows\System32\DeployCapture.ps1

:: > one of these will override the existing content >> will add to the file.
echo wpeinit>%start_directory%\WinPE_amd64_PS\mount\Windows\System32\startnet.cmd

call %start_directory%\CustomizeImage.bat

:: Add to the startup script of the image the command to allow the execution of powershell scripts.
ECHO powershell Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine>>%start_directory%\WinPE_amd64_PS\mount\Windows\System32\startnet.cmd

:: Add to the startup script of the image the command to actually run the powershell script on startup automatically.
ECHO powershell \Windows\System32\DeployCapture.ps1>>%start_directory%\WinPE_amd64_PS\mount\Windows\System32\startnet.cmd

echo Customized image!

:: ------------------------------------   END Customize the image ------------------------------------   

set /p "choice=Create iso file? (y / n): "

:: Ask if the user is sure that he wants to generalize the system.
if %choice%==y (
    call %start_directory%\Unmount.bat
)

echo Done!
pause