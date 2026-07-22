@echo off

title Running %~nx0 ...

call :isAdmin && (
	set logBaseDir=D:
) || (
	set logBaseDir=.
)

set utf16LogFile=%logBaseDir%\%~n0_%computername%.utf16
set logFile=%logBaseDir%\%~n0_%computername%.log
set nfoFile=%logBaseDir%\%computername%.nfo

for %%f in (%utf16LogFile% %logFile% %nfoFile%) do (
	call :testRW %%f || (
		echo =^> ERROR: You don't have write access to the file %%f.>&2
		exit/b 1
	)
)

set tailTool=tail.exe
set toolList=tail sed
set zipFile=%~n0.zip

call :installTools %zipFile% %toolList% || exit/b

echo.> %utf16LogFile%
echo =^> Showing the log file: %utf16LogFile% in real time on the child window, it takes about five minutes ...
start "%utf16LogFile:"=%: System Information" %comspec% /c "mode 120,4000 && tail -f %utf16LogFile% | sed "s/\x0//g"

(
	echo =^> Starting of the script %0 on the %date% at %time% by the user %username% on computer %computername% ...
	echo.
	echo =^> Windows version :
	wmic os get name,csdversion
	echo.
	echo =^> FQDN and IP address of server %computername% :
	nslookup %computername% | tail +3
	echo =^> Searching the "tomnt.log" file on the D: drive ...
	setlocal enabledelayedexpansion
	for /f "tokens=*" %%a in ('dir D:\tomnt.log /b /s') do (set tomIniFile=%%a& echo ==^> Found the file = "%%a")
	if defined tomIniFile (
		echo ==^> TOM version:
		findstr -r V[0-9] "!tomIniFile!"
	)
	endlocal
	echo.
	echo =^> Java version:
	java -version
	echo.
	echo =^> WSH Release:
	echo wscript.echo "Microsoft Windows Script Host Version: " ^& ScriptEngineMajorVersion ^& "." ^& ScriptEngineMinorVersion ^& "." ^& ScriptEngineBuildVersion^&vbCRLF> wsh_version_tmp.vbs
	cscript -nologo wsh_version_tmp.vbs
	del wsh_version_tmp.vbs
	echo =^> Fetching diskdrive, partitions and volume informations ...
	echo list disk > storage_info.dpt
	echo select disk 0 >> storage_info.dpt
	echo list partition >> storage_info.dpt
	echo list volume >> storage_info.dpt
	echo exit >> storage_info.dpt
	diskpart -s storage_info.dpt
	del storage_info.dpt
	echo.
	echo =^> Get Terminal Server RDP port:
	reg query "hklm\system\currentcontrolset\control\terminal server\winstations\rdp-tcp" /v PortNumber
	echo =^> Currently connected User list :
	quser
	echo.
	echo =^> Currently opened RDP session list :
	qwinsta
	echo.
	echo =^> Current User info. :
	net user %username% 2>nul: || net user %username% /dom
	if defined USERDNSDOMAIN (
		echo =^> Current User groups membership in the domain %UserDnsDomain% :
		for /f "tokens=2 delims=,=" %%g in ('dsquery user -name %username% ^| dsget user -memberof') do echo %%g
	) else (
		echo =^> Current User groups membership :
		gpresult | tail +40
	)
	echo.
	echo =^> Current User Regionnal Settings:
	reg query "HKCU\Control Panel\International"
	echo.
	echo =^> Default User Regionnal Settings:
	reg query "HKU\.DEFAULT\Control Panel\International"
	echo.
	echo =^> OS Configuration Information for %computername% :
	dir %windir%\system32\systeminfo.exe >nul && systeminfo | findstr -v -r "KB[0-9]*"  | findstr -v -c:": File 1"
	echo.
) > %utf16LogFile% 2>&1

call :timer "call :software_list" >> %utf16LogFile% 2>&1
call :timer "call :wmic_info" >> %utf16LogFile% 2>&1

(
	echo =^> Listing scheduled tasks
	schtasks -query -v
	echo.
	echo =^> Computing msinfo32 information into %nfoFile% at %time%, it can take 100%% of the CPU for up to 5 minutes ...
	echo =^> You can interrupt this by killing the "msinfo32.exe" process if you wish ...
	call :timer "start /wait msinfo32 -nfo %nfoFile%"
	echo.
	echo =^> Done.
	echo =^> End time: %time%>nul
) >> %utf16LogFile% 2>&1

echo =^> End time: %time% >> %utf16LogFile%

::echo =^> Press any key to close the log window ... & pause > nul
taskkill -im %tailTool% -f

echo =^> Converting %utf16LogFile% to DOS ANSI ...
::sed "s/\x0//g;" %utf16LogFile% | sed "s/ *$//;" | sed "s/$/\r/" > %logFile% && del %utf16LogFile%
sed "s/\x0//g;" %utf16LogFile% | sed "s/ *$//;s/$/\r/" > %logFile% && del %utf16LogFile%

call :isAdmin && (
	if not %computername%==MA5165014 if not %computername%==DMIL2K01 del %zipFile%
) || del tail.exe sed.exe

::exit

echo =^> Please, send the file %logFile% and %nfoFile% to us.
echo.
title Command Prompt
goto :eof

:installTools
	setlocal enabledelayedexpansion
	set l_zipFile=%1
	if not defined l_zipFile (
		echo %0 zipFileName tool1 tool2 tool3 ...>&2
		exit/b
	)
	shift

	set toolList=%1 %2 %3 %4 %5 %6 %7 %8 %9
	call :isAdmin && (set dstDir=%windir%\system32) || set dstDir=.
	for %%t in (!toolList!) do (
		set tool=%%t
		!tool! -h >nul 2>&1
		set rc=!errorlevel!
		if !rc!==9009 (
			if exist %zipFile% (
				unzip -oq %l_zipFile% !tool!
				move/y !tool! !dstDir!\!tool!.exe >nul
			) else (
				echo =^> ERROR: %l_zipFile% does not exist.>&2
				exit/b 1
			)
		)
	)
	endlocal

	goto :eof

:software_list
	for /f "skip=3" %%k in ('reg query hklm\software\microsoft\windows\currentversion\uninstall ^| findstr -v -r "KB[0-9]*"') do (
		reg query %%k /v DisplayName 2>nul
	) | find/i "DisplayName"
	echo.
	goto :eof

:timer
	setlocal enabledelayedexpansion
	set command=%*
	set command=%command:~1,-1%

	set startTime=%time%
	set startTime_hour=%startTime:~0,2%
	set startTime_min=%startTime:~3,2%
	set startTime_sec=%startTime:~6,2%

	if %startTime_hour% lss 10 set startTime_hour=%startTime_hour:~1,1%
	if %startTime_min% lss 10 set startTime_min=%startTime_min:~1,1%
	if %startTime_sec% lss 10 set startTime_sec=%startTime_sec:~1,1%

	echo =^> Running ^<%command%^> ...
	%command%

	set endTime=%time%
	set endTime_hour=%endTime:~0,2%
	set endTime_min=%endTime:~3,2%
	set endTime_sec=%endTime:~6,2%

	if %endTime_hour% lss 10 set endTime_hour=%endTime_hour:~1,1%
	if %endTime_min% lss 10 set endTime_min=%endTime_min:~1,1%
	if %endTime_sec% lss 10 set endTime_sec=%endTime_sec:~1,1%

	set /a total_sec=%endTime_sec%-%startTime_sec%
	if %total_sec% lss 0 (
		set /a total_sec+=60
		set /a endTime_min-=1
	)

	set /a total_min=%endTime_min%-%startTime_min%
	if %total_min% lss 0 (
		set /a total_min+=60
		set /a endTime_hour-=1
	)

	set /a total_hour=%endTime_hour%-%startTime_hour%

	set total=%total_hour%:%total_min%:%total_sec%

	echo =^> Total time is: %total%
	echo.

	endlocal
	goto :eof

:wmic_info
	setlocal
	set funcName=%0
	set funcName=%funcName::=%

	call :isAdmin || (
		echo =^> [%funcName%] ERROR: You have to belong to the administrators group to run wmic.>&2
		exit/b 1
	)

	echo =^> Basebord info. ...
	wmic baseboard list brief
	echo =^> Bios info. ...
	wmic bios list brief
	echo =^> CDROM info. ...
	wmic cdrom list brief
	echo =^> Computer info. ...
	wmic computersystem list brief
	echo =^> CPU info. ...
	wmic cpu get name,socketdesignation,maxclockspeed,numberofcores,numberoflogicalprocessors
	echo =^> CSPRODUCT info. ...
	wmic csproduct list brief
	echo =^> dcomapp info. ...
	wmic dcomapp list brief
	echo =^> Screen info. ...
	wmic desktopmonitor list brief
	echo =^> Diskdrive info. ...
	wmic diskdrive list brief
	echo =^> Environment info. ...
	wmic environment list brief
	echo =^> IDE Controller info. ...
	wmic idecontroller list brief
	echo =^> IRQ Controller info. ...
	wmic irq list brief
	echo =^> Lecteurs logiques :
	wmic logicaldisk list brief
	echo =^> Logon info. ...
	wmic logon list brief
	echo =^> Memphysical info. ...
	wmic memphysical list brief
	echo =^> Netuse info. ...
	wmic netuse list brief
	echo =^> nic info. ...
	wmic nic list brief
	echo =^> nicconfig info. ...
	wmic nicconfig where ipenabled='true' list brief
	echo =^> NTDomain info. ...
	wmic ntdomain list brief
	echo =^> Nteventlog info. ...
	wmic nteventlog list brief
	echo =^> OS info. ...
	wmic os list brief
	echo =^> Pagefile info. ...
	wmic pagefile
	echo =^> Partition info. ...
	wmic partition list brief
	echo =^> portconnector info. ...
	wmic portconnector list
	echo =^> Printer info. ...
	wmic printer list brief
	echo =^> Printerconfig info. ...
	wmic printerconfig list brief
	echo =^> printjob info. ...
	wmic printjob list brief
	echo =^> Process info. ...
	wmic process list brief
	echo =^> Quick Fix Engineering info. ...
	wmic qfe list brief
	echo =^> Service info. ...
	wmic service list brief
	echo =^> Share info. ...
	wmic share list brief
	echo =^> Sounddev info. ...
	wmic sounddev list brief
	echo =^> Startup info. ...
	wmic startup list
	echo =^> Sysaccount info. ...
	wmic sysaccount list brief
	echo =^> Sysdriver info. ...
	wmic sysdriver list brief
	echo =^> Systemenclosure info. ...
	wmic systemenclosure list brief
	echo =^> Temperature info. ...
	wmic temperature list brief
	echo =^> Timezone info. ...
	wmic timezone list
	echo =^> Voltage info. ...
	wmic voltage list brief
	echo =^> Product info. ...
	wmic product list brief
	echo =^> softwarefeature info. ...
	wmic softwarefeature get Caption,ProductName,Version

	endlocal
	goto :eof

:isAdmin
	copy/y nul %windir%\system32\test >nul 2>&1 && del %windir%\system32\test || exit/b
	goto :eof

:testRW
	setlocal
	set file=%1
	copy/y nul %file% >nul 2>&1 && del %file% || exit/b

	endlocal
	goto :eof
