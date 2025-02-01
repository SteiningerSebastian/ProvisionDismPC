:: Author: Sebastian Steininger (sebastian.steininger@outlook.com)

@echo off

:: BatchGotAdmin Author: Eneerge @ https://sites.google.com/site/eneerge/scripts/batchgotadmin
::-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"="
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

::-------------------------------------

:: Remember where the file is placed.
SET start_directory=%~dp0

cd %start_directory%

:: Make sure that we are allowed to execute the script
powershell Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine

:: Prepare the system for sysprep generalize CopyProfile
powershell /CAPTURE/PrepareCapture.ps1

:: Make sure that others are not allowed to execute scripts
powershell Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope LocalMachine

cd %start_directory%

:: Copy file to to autostart.
copy /Y autostart.bat "%programdata%\Microsoft\Windows\Start Menu\Programs\StartUp\autostart.bat"

:: Sysprep generalize the PC with the unattended file, prepare for capture.
set /p "choice=Do you want to generalize this pc? (y / n): "

:: Ask if the user is sure that he wants to generalize the system.
if %choice%==y (
	cd \
	%windir%\system32\sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:%start_directory%\unattend.xml
)

pause