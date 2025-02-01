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

:: Make sure that we are allowed to execute the script
powershell Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine

powershell /CAPTURE/setup.ps1

:: Make sure that others are not allowed to execute scripts
powershell Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope LocalMachine

:: Remove all folders and files used for setup
cd \
copy \CAPTURE\final.bat final.bat

:: Start the final bat to remove all files. Clean Up!
START \final.bat