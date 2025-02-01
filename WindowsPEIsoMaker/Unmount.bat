:: Author: Sebastian Steininger (sebastian.steininger@outlook.com)

@echo off

:: Remember where the file is placed.
SET start_directory=%~dp0

echo Commiting and unmounting the image ....
	
:: Unmounting the configured image
Dism /Unmount-Image /MountDir:%start_directory%/WinPE_amd64_PS/mount /Commit

echo Unmounted image!

echo Generating Iso ...
if exist WinPE_amd64.iso del WinPE_amd64.iso

:: Start the Deployment and Imaging Tools Environment
call "%programfiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"

if exist %start_directory%/WinPE_amd64.iso del %start_directory%/WinPE_amd64.iso

:: Give the filesystem time to clear locks on files.
@timeout /t 3 /nobreak

:: Make an iso from the unmounted directory
MakeWinPEMedia /ISO %start_directory%/WinPE_amd64_PS %start_directory%/WinPE_amd64.iso

echo Done, created WinPE_amd64.iso!