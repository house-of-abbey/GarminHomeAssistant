@echo off
rem -----------------------------------------------------------------------------------
rem
rem  Distributed under MIT Licence
rem    See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE
rem
rem -----------------------------------------------------------------------------------
rem
rem  GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
rem  tested on a Venu 2 device. The source code is provided at:
rem             https://github.com/house-of-abbey/GarminHomeAssistant
rem
rem  J D Abbey & P A Abbey, 11 November 2025
rem
rem  Run the icon generation Python scripts
rem
rem -----------------------------------------------------------------------------------

REM change the current directory to the batch file's location
cd /d %~dp0
python iconResize.py
python launcherIconResize.py
pause
