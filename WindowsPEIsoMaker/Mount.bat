:: Author: Sebastian Steininger (sebastian.steininger@outlook.com)

@echo off

:: Remember where the file is placed.
SET start_directory=%~dp0

echo mounting image ...

:: Mounting the image to configure it.
Dism /Mount-Image /ImageFile:"%start_directory%/WinPE_amd64_PS/media/sources/boot.wim" /Index:1 /MountDir:"%start_directory%/WinPE_amd64_PS/mount"

:: Wait for the system to clear all locks on files.
@timeout /t 3 /nobreak

echo Mounted image!