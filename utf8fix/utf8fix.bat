@echo off
setlocal EnableDelayedExpansion EnableExtensions

if "%1" equ "" (
    echo Fixes BOM ^(byte order mark^) of bat files saved as UTF-8
    echo Inserts @echo off and a change of codepage + rem before BOM
    echo.
    echo Save a batfile with UTF-8 chars and a blank first line
    echo Use encoding UTF-8 in notepads "Save As"
    echo.
    echo Example:
    echo     oeaeaa_error.bat 
    echo.
    echo Gives a error at the beginning
    echo.
    echo     utf8fix oeaeaa_error.bat oeaeaa.bat 
    echo     oeaeaa.bat 
    echo.
    echo No more error
    echo.
) else (
    echo Fixing %1
    set thefile=%1
    set newfile=%2
    set fixfile=%thefile%.fix
    echo @echo off > %fixfile%
    echo chcp 65001 ^> nul >> %fixfile%
    echo | set /p="rem " >> %fixfile%
    copy /b %fixfile% + %thefile% %newfile% > nul
    del %fixfile%
)