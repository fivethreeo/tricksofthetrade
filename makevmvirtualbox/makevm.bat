@echo off
setlocal EnableDelayedExpansion EnableExtensions

set /p "MACHINENAME=Machine name (no spaces):"
set /p "TOKEN=ETCD Token:"
set "INTNET=%MACHINENAME%"
set "SHAREDDIR=%cd%\shared"
set "HDD=%cd%\%MACHINENAME%.vdi"
set "ISO=%cd%\%MACHINENAME%.iso"
set "SHARENAME=%MACHINENAME%"

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

rem go get github.com/fivethreeo/create-coreos-vdi
rem go get github.com/fivethreeo/create-basic-configdrive

echo Buildig coreos tools
go build -o .\create-coreos-vdi.exe github.com/fivethreeo/create-coreos-vdi
go build -o .\create-basic-configdrive.exe github.com/fivethreeo/create-basic-configdrive

create-coreos-vdi

for /F "tokens=1,2 delims=:" %%G in ('dir /b coreos*.vdi ^| findstr /n "^"') do if %%G equ 1 set "CLONEVDI=%%H"
for /F "tokens=1,2 delims=:" %%G in ('dir /b "*.pub" ^| findstr /n "^"') do if %%G equ 1 set "PUBKEY=%%H"

create-basic-configdrive -H %MACHINENAME% -S %PUBKEY% -t %TOKEN%

echo cloning "%CLONEVDI%" to "%MACHINENAME%.vdi"
VBoxManage clonehd "%CLONEVDI%" "%MACHINENAME%.vdi"
VBoxManage modifyhd "%MACHINENAME%.vdi" --resize 10240

VBoxManage createvm --name "%MACHINENAME%" --register

VBoxManage modifyvm "%MACHINENAME%" --memory 1024 --vram 128


echo Adding bridged nic using interface "%BRIDGEADAPTER%"%.
VBoxManage modifyvm "%MACHINENAME%" --nic1 bridged --bridgeadapter1 "%BRIDGEADAPTER%"

echo Adding internal net "%INTNET%" nic
VBoxManage modifyvm "%MACHINENAME%" --nic2 intnet --intnet2 %INTNET% --nicpromisc2 allow-vms


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

VBoxManage startvm "%MACHINENAME%"