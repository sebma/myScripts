@echo off

set zipFile=%~n0.zip
if exist %zipFile% (
	unzip -oq %zipFile%
	del %zipFile%
) else (
	echo =^> ERROR: %zipFile% does not exist.>&2
	exit/b 1
)

set toolList=tail sed
setlocal enabledelayedexpansion
for %%t in (%toolList%) do (
	set tool=%%t
	!tool! -h >nul 2>&1
	set rc=!errorlevel!
	if !rc!==9009 (
		move /y !tool! %windir%\system32\!tool!.exe >nul
	) else (
		del !tool!
	)
)
endlocal

move /y .\wsh_version .\wsh_version.vbs
cscript .\wsh_version.vbs
del .\wsh_version.vbs
::call :timer "start /w msinfo32 -nfo %SystemDrive%\%computername%.nfo"
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
