@echo off
setlocal EnableDelayedExpansion EnableExtensions

rem Install virtualbox and extensions
rem Install golang and set up PATH, GOROOT and GOPATH
rem Drop a ssh pubkey with the extension .pub in the same directory as this file
rem Key must be in ssh-(rsa|dsa) KEY form. No headers like ------------------
rem Copy from puttygen do not save from puttygen.
rem Run this batch file, use --noget if you change the go programs locally
rem Log in using username core using the private key in putty

for /F "tokens=1,2 delims=:" %%G in ('dir /b "*.pub" 2^>nul ^| findstr /n "^"') do if %%G equ 1 set "PUBKEY=%%H"

IF "%PUBKEY%"=="" ( 
  echo No ssh pubkey found in directory
  GOTO End
)

set /p "MACHINENAME=Machine name (no spaces): "
set /p "TOKEN=ETCD Token: "
set /p "INTNET=Internal net name(empty for no internal net): "
set /p "COREOSVER=Coreos version(default stable): "
set "SHAREDDIR=%cd%\shared"
set "HDD=%cd%\%MACHINENAME%.vdi"
set "ISO=%cd%\%MACHINENAME%.iso"
set "SHARENAME=%MACHINENAME%"

IF "%COREOSVER%"=="" ( 
  set "COREOSVER=stable"
)

set KEY_NAME=HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\VirtualBox
set VALUE_NAME=InstallDir

FOR /F "usebackq skip=2 tokens=1-3,4,5,6" %%A IN (`reg query %KEY_NAME% /v %VALUE_NAME% /reg:64 2^>nul`) DO (
    set ValueName=%%A
    set ValueType=%%B
    set VirtualBox=%%C %%D
)

if defined ValueName (
    rem @echo Value Name = %ValueName%
    rem @echo Value Type = %ValueType%
    rem @echo Value Value = %ValueValue%
) else (
    @echo VirtualBox not found.
)

rem VirtualBox=%%C %%D no %%E
rem set VirtualBox=%VirtualBox:~0,-1%
echo VirtualBox location %VirtualBox%

rem Set path to avoid spaces in command in for expression
set PATH=%PATH%;%VirtualBox%

rem Get name of first network bridge interface
for /F "tokens=1,3 delims=:" %%G in ('VBoxManage list bridgedifs ^| findstr "^Name:" ^| findstr /n "^"') do if %%G equ 1 set "BRIDGEADAPTER=%%H"

rem Strip spaces from BRIDGEADAPTER
for /f "tokens=* delims= " %%a in ("%BRIDGEADAPTER%") do set BRIDGEADAPTER=%%a
for /l %%a in (1,1,100) do if "!BRIDGEADAPTER:~-1!"==" " set BRIDGEADAPTER=!BRIDGEADAPTER:~0,-1!

if not exist "create-coreos-vdi.exe" (
  echo Buildig create-coreos-vdi
  if not "%1"=="--nogo" (
    go get github.com/fivethreeo/create-coreos-vdi
  )
  go build -o .\create-coreos-vdi.exe github.com/fivethreeo/create-coreos-vdi
)

if not exist "create-basic-configdrive.exe" (
  echo Buildig create-basic-configdrive
  if not "%1"=="--nogo" (
    go get github.com/fivethreeo/create-basic-configdrive
  ) 
  go build -o .\create-basic-configdrive.exe github.com/fivethreeo/create-basic-configdrive
)
for /F "tokens=1,2 delims=:" %%G in ('dir /b coreos*.vdi 2^>nul ^| findstr /n "^"') do if %%G equ 1 set "CLONEVDI=%%H"

IF "%CLONEVDI%"=="" ( 
  create-coreos-vdi -V %COREOSVER%
  for /F "tokens=1,2 delims=:" %%G in ('dir /b coreos*.vdi 2^>nul ^| findstr /n "^"') do if %%G equ 1 set "CLONEVDI=%%H"
)

IF "%CLONEVDI%"=="" ( 
  echo No vdi created, debug script
  GOTO End
)
echo create-basic-configdrive -H %MACHINENAME% -S %PUBKEY% -t %TOKEN%
create-basic-configdrive -H %MACHINENAME% -S %PUBKEY% -t %TOKEN%

if exist "%MACHINENAME%.vdi" (
  echo Not cloning "%CLONEVDI%" to "%MACHINENAME%.vdi", clone already exists.
  GOTO StartVM
)

if not exist "%MACHINENAME%.vdi" (
  echo cloning "%CLONEVDI%" to "%MACHINENAME%.vdi"
  VBoxManage clonehd "%CLONEVDI%" "%MACHINENAME%.vdi"
)

VBoxManage modifyhd "%MACHINENAME%.vdi" --resize 10240

VBoxManage createvm --name "%MACHINENAME%" --register

VBoxManage modifyvm "%MACHINENAME%" --memory 1024 --vram 128

echo Adding bridged nic using interface "%BRIDGEADAPTER%"%.
VBoxManage modifyvm "%MACHINENAME%" --nic1 bridged --bridgeadapter1 "%BRIDGEADAPTER%"

IF not "%INTNET%"=="" (
  echo Adding internal net "%INTNET%" nic
  VBoxManage modifyvm "%MACHINENAME%" --nic2 intnet --intnet2 %INTNET% --nicpromisc2 allow-vms
)

VBoxManage storagectl "%MACHINENAME%" --name "IDE Controller" --add ide

echo Adding harddrive %HDD%.
VBoxManage storageattach "%MACHINENAME%" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium %HDD%

echo Adding iso media %ISO%.
VBoxManage storageattach "%MACHINENAME%" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium %ISO%

echo Adding shared dir "%SHAREDDIR%" as "%SHARENAME%".

if not exist "%SHAREDDIR%\." (
  mkdir %SHAREDDIR%
)

VBoxManage sharedfolder add "%MACHINENAME%" --name "%SHARENAME%" --hostpath "%SHAREDDIR%"

:StartVM

VBoxManage startvm "%MACHINENAME%"

:End
pause
