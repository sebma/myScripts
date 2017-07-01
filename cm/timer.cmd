@echo off
set commandToRun=%~1
shift /1
set argumentsToRun=%1 %2 %3 %4 %5 %6 %7 %8 %9

if not defined commandToRun (
	echo %0 commandToRun >&2
	exit/b 1
)

call :timer %commandToRun% %argumentsToRun%
@goto :eof

:timer
	setlocal enabledelayedexpansion
	set command=%~1
	set firstArgument=%2
	shift /1
	set arguments=%1 %2 %3 %4 %5 %6 %7 %8 %9
	set arguments=%arguments:  =%
	REM set command=%command:~1,-1%

	set startTime=%time%
	set startTime_hour=%startTime:~0,2%
	set startTime_min=%startTime:~3,2%
	set startTime_sec=%startTime:~6,2%

	if %startTime_hour% lss 10 set startTime_hour=%startTime_hour:~1,1%
	if %startTime_min% lss 10 set startTime_min=%startTime_min:~1,1%
	if %startTime_sec% lss 10 set startTime_sec=%startTime_sec:~1,1%

	echo =^> Timing the command ^<%command% %arguments%^> started at !time! ...
	call %command% %arguments%

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

	echo. >&2
	echo =^> The command ^<%command%^> took %total% to run. >&2

	endlocal
	goto :eof
