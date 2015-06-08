@echo off
setlocal EnableDelayedExpansion

if /I "%1" EQU "" (
  echo.
  echo Usage:
  echo %0 commandid *.filetype "Command label" "commandtorun \"^%%1\""
  echo.
  echo Example:
  echo %0 cobsuscate *.c "Obfuscate c code" "cobfuscator.exe \"^%%1\""
  echo.
)
if /I "%1" NEQ "" (
  echo Windows Registry Editor Version 5.00 > %1.reg
  echo. >> %1.reg
  echo [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\%2\shell\%1] >> %1.reg
  echo @=^"%~3^" >> %1.reg
  echo. >> %1.reg
  echo [HKEY_LOCAL_MACHINE\SOFTWARE\Classes\%2\shell\%1\command] >> %1.reg
  echo @=^"%~4^" >> %1.reg
)