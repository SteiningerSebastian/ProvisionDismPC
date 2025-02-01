:: Author: Sebastian Steininger (sebastian.steininger@outlook.com)

@echo off

echo Waiting for processes to free lock on files, so they can be deleted ...

:: Timout for the system to clear any locks on the files.
timeout /t 5

:: Delete the autostart file from the folder.
del /f /s /q "%programdata%\Microsoft\Windows\Start Menu\Programs\StartUp\autostart.bat"

cd \

:: Remove all files and the folder used to capture this pc.
del /f /s /q \CAPTURE 1>nul

:: Remove the folder.
cd \
rmdir /q /s CAPTURE

echo Done, you may shutdown the PC now!

:: Delete this file.
del \final.bat

pause