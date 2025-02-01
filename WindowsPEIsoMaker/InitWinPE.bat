:: Author: Sebastian Steininger (sebastian.steininger@outlook.com)

@echo off 

:: Remove the folder.
rmdir /s /q WinPE_amd64_PS

:: Remember where the file is placed.
SET start_directory=%~dp0

:: Start DISM and cleanup the wims
%SystemRoot%\System32\Dism.exe /cleanup-wim

:: Switch to the directory where the file is placed.
cd %start_directory:~0,-1%

:: Start the Deployment and Imaging Tools Environment
call "%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"

:: Copy the new files to the folder.
copype.cmd amd64 %start_directory:~0,-1%\WinPE_amd64_PS

:: Wait for the filesystem to clear lock on files.
@timeout /t 3 /nobreak