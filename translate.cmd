@echo off
rem -----------------------------------------------------------------------------------
rem
rem  Distributed under MIT Licence
rem    See https://github.com/house-of-abbey/GarminHomeAssistant/blob/main/LICENSE.
rem
rem -----------------------------------------------------------------------------------
rem
rem  GarminHomeAssistant is a Garmin IQ application written in Monkey C and routinely
rem  tested on a Venu 2 device. The source code is provided at:
rem             https://github.com/house-of-abbey/GarminHomeAssistant.
rem
rem  J D Abbey & P A Abbey, 28 December 2022
rem
rem  Run the automatic translation script.
rem
rem  Reference:
rem   * Using Monkey C from the Command Line
rem     https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/
rem
rem -----------------------------------------------------------------------------------

rem 'pip' instructs us to add this to the PATH for 'websockets.exe' and 'httpx.exe'
PATH=%PATH%;%USERPROFILE%\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0\LocalCache\local-packages\Python311\Scripts
rem pip install google-genai beautifulsoup4 lxml
rem Read the API key from a text file excluded from git.
rem Copy the API key from your project in https://aistudio.google.com/app/apikey into this file.
set /p GEMINI_API_KEY=<".\gemini_api_key.txt"
rem echo Using Gemini API Key: %GEMINI_API_KEY%
python translate.py
pause
