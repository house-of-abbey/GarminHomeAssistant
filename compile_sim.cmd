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
rem  J D Abbey & P A Abbey, 28 December 2022
rem
rem  For use when VS Code is misbehaving and failing to recompile before starting a simulation.
rem
rem  Reference:
rem   * Using Monkey C from the Command Line
rem     https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/
rem
rem -----------------------------------------------------------------------------------

rem Check this path is correct for your Java installation
set JAVA_PATH=C:\Program Files\Java\jdk-22\bin
rem SDK_PATH should work for all users
set /p SDK_PATH=<"%USERPROFILE%\AppData\Roaming\Garmin\ConnectIQ\current-sdk.cfg"
set SDK_PATH=%SDK_PATH:~0,-1%\bin
rem Assume we can create and use this directory
set DEST=bin

rem Device for simulation
set DEVICE=venu2
set JUNGLE=monkey.jungle

rem C:\>java -jar %SDK_PATH%\monkeybrains.jar -h
rem usage: monkeyc [-a <arg>] [-b <arg>] [--build-stats <arg>] [-d <arg>]
rem        [--debug-log-level <arg>] [--debug-log-output <arg>]
rem        [--disable-api-has-check-removal] [--disable-v2-opcodes] [-e]
rem        [--Eno-invalid-symbol] [-f <arg>] [-g] [-h] [-i <arg>] [-k] [-l <arg>]
rem        [-m <arg>] [--no-gen-styles] [-o <arg>] [-O <arg>] [-p <arg>] [-r] [-t]
rem        [-u <arg>] [-v] [-w] [-x <arg>] [-y <arg>] [-z <arg>]
rem -a,--apidb <arg>                  API import file
rem -b,--apimir <arg>                 API MIR file
rem    --build-stats <arg>            Print build stats [0=basic]
rem -d,--device <arg>                 Target device
rem    --debug-log-level <arg>        Debug logging verbosity [0=errors, 1=basic,
rem                                   2=intermediate, 3=verbose]
rem    --debug-log-output <arg>       Output log zip file
rem    --disable-api-has-check-removalDo not optimize out API has checks
rem    --disable-v2-opcodes           Do not use the v2 opcodes
rem -e,--package-app                  Create an application package.
rem    --Eno-invalid-symbol           Do not error when a symbol is found to be
rem                                   invalid
rem -f,--jungles <arg>                Jungle files
rem -g,--debug                        Print debug output
rem -h,--help                         Prints help information
rem -i,--import-dbg <arg>             Import api.debug.xml
rem -k,--profile                      Enable profiling support
rem -l,--typecheck <arg>              Type check [0=off, 1=gradual, 2=informative,
rem                                   3=strict]
rem -m,--manifest <arg>               Manifest file (deprecated)
rem    --no-gen-styles                Do not generate Rez.Styles module
rem -o,--output <arg>                 Output file to create
rem -O,--optimization <arg>           Optimization level [0=none, 1=basic, 2=fast
rem                                   optimizations, 3=slow optimizations]
rem                                   [p=optimize performance, z=optimize code
rem                                   space]
rem -p,--project-info <arg>           projectInfo.xml file to use when compiling
rem -r,--release                      Strip debug information
rem -t,--unit-test                    Enables compilation of unit tests
rem -u,--devices <arg>                devices.xml file to use when compiling
rem                                   (deprecated)
rem -v,--version                      Prints the compiler version
rem -w,--warn                         Show compiler warnings
rem -x,--excludes <arg>               Add annotations to the exclude list
rem                                   (deprecated)
rem -y,--private-key <arg>            Private key to sign builds with
rem -z,--rez <arg>                    Resource files (deprecated)

title Compiling for %DEVICE%

rem Batch file's directory where the source code is
set SRC=%~dp0
rem drop last character '\'
set SRC=%SRC:~0,-1%

if exist %DEST% (
  rmdir /s /q %DEST%
)
rem The above may not successfully delete the directory if there are locked files
if not exist %DEST% (
  mkdir %DEST%
)

echo.
echo Starting compilation for simulation on '%DEVICE%'.
echo.

rem call %SDK_PATH%\connectiq.bat
start "Simulator" "%SDK_PATH%\simulator.exe"

rem Compile PRG for a single device for side loading
"%JAVA_PATH%\java.exe" ^
  -Xms1g ^
  -Dfile.encoding=UTF-8 ^
  -Dapple.awt.UIElement=true ^
  -jar %SDK_PATH%\monkeybrains.jar ^
  --output %SRC%\bin\HomeAssistant.prg ^
  --jungles %SRC%\%JUNGLE% ^
  --private-key %SRC%\..\developer_key ^
  --device %DEVICE%_sim ^
  --warn

rem  --release

if %ERRORLEVEL% equ 0 (
  %SDK_PATH%\monkeydo.bat %SRC%\bin\HomeAssistant.prg %DEVICE%
) else (
  rem Wait to see errors
  pause
)
