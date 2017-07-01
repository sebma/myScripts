@echo off
setlocal

set "winver[4.00.950]=Windows 95"
set "winver[4.00.1111]=Windows 95 OSR2"
set "winver[4.00.1381]=Windows NT4"
set "winver[4.10.1998]=Windows 98"
set "winver[4.10.2222]=Windows 98 SE"
set "winver[4.90.3000]=Windows ME"
set "winver[5.00.2195]=Windows 2000"
set "winver[5.1.2600]=Windows XP"
set "winver[5.2.3790]=Windows Server 2003"
set "winver[6.0.6000]=Windows Vista/Server 2008"
set "winver[6.0.6002]=Windows Vista SP2"
set "winver[6.1.7600]=Windows 7/Server 2008 R2"
set "winver[6.1.7601]=Windows 7 SP1/Server 2008 R2 SP1"
set "winver[6.2.9200]=Windows 8/Server 2012"
set "winver[6.3.9600]=Windows 8.1/Server 2012 R2"

for /f "tokens=2 delims=[]" %%a in ('ver.exe') do 	for /f "tokens=2-4 delims=. " %%b in ("%%a") do set /a "version=%%b", "subversion=%%c", "build=%%d"

if defined winver[%version%.%subversion%.%build%] (
	call echo You are using: %%winver[%version%.%subversion%.%build%]%%
) else (
	echo unknown version, or ver.exe is missing: %version%.%subversion%.%build%
)

call set label=%%winver[%version%.%subversion%.%build%]%%
set label=%label: =_%
goto :%label%
endlocal
goto :eof

:Windows_8
echo Windows 8
goto :eof

:Windows_7
echo Windows 7
goto :eof

:Windows_XP
echo Bienvenu sur Windows XP
goto :eof

:Windows_Server_2003
echo Bienvenu sur Windows Server 2003
goto :eof
