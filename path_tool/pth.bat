@echo off
setlocal EnableDelayedExpansion EnableExtensions

echo ø
set args=%*
if "%args%" neq "" (
  set "debug=%args:debug=%"
)
echo %args%
if "%debug%" neq "%args%" (
  @echo on
)
set HOMEDIR=%HOMEDRIVE%%HOMEPATH%

echo %0
echo %HOMEDIR%

if not exist "%HOMEDIR%\pth.bat" (
  echo Copying %0 to %HOMEDIR%\pth.bat
  copy %0 %HOMEDIR%\pth.bat
)

set "pth_default=%HOMEDIR%\pth_default.bat"
del %pth_default%
if not exist %pth_default% (
  echo No pth_default.bat found in %HOMEDIR%
  echo Create it ^(y/n^)^?
  choice /c yn /n /t 5 /d n  > nul
  if !errorlevel!==1 (
    set "create_file=%pth_default%"
    goto do_create_file
  )
)
goto end

:do_create_file
set "setstr=set PATH^="
set "var=%PATH:"=""%"
set "var=%var:^=^^%"
set "var=%var:&=^&%"
set "var=%var:|=^|%"
set "var=%var:<=^<%"
set "var=%var:>=^>%"
set "var=%var:;=^;^;%"
set var=%var:""="%
set "var=%var:"=""Q%"
set "var=%var:;;="S"S%"
set "var=%var:^;^;=;%"
set "var=%var:""="%"
set "var=!var:"Q=!"
for %%a in ("!var:"S"S=";"!") do (
  
  if %%a neq "" (
    set "pt=%%a"
    echo Add !pt! to pathfile ^(y/n^)^?
    choice /c yn /n /t 5 /d y > nul
    if !errorlevel!==1 (
      set "setstr=!setstr!!pt:~1,-1!;"
    )
  )
)
echo Created %create_file%
echo %setstr% > %create_file%
:end

pause
