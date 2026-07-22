@echo off

:main
	call :getdate_vbs
	call :getdate_wmic
	call :getdate_dos

	echo YYYYMMDD = %YYYYMMDD%

	goto :eof

:getdate_dos
	set sysDate=%date:* =%
	set Day=%sysDate:~0,2%
	set Month=%sysDate:~3,2%
	set Year=%sysDate:~6,4%
	set YYYYMMDD=%Year%%Month%%Day%

	goto :eof

:getdate_vbs
	setlocal
	set funcName=%0
	set funcName=%funcName::=%

	set getdateVBScriptName=getdate_tmp.vbs
	echo wscript.echo 10^^4*year(now) + 100*month(now) + day(now) > %getdateVBScriptName%
	::cscript -nologo %getdateVBScriptName%

	for /f %%G in ('cscript /nologo %getdateVBScriptName%') do set _dtm=%%G

	del %getdateVBScriptName%

	set _yyyy=%_dtm:~0,4%
	set _mm=%_dtm:~4,2%
	set _dd=%_dtm:~6,2%
	set _date1=%_dd%/%_mm%/%_yyyy%
	echo =^> Function %funcName%: %_date1%

	endlocal
	goto :eof

:getdate_wmic
	::YOU HAVE TO BELONG TO THE ADMINISTRATORS GROUP TO RUN WMIC
	setlocal
	set funcName=%0
	set funcName=%funcName::=%

	wmic /? 2>&1 | findstr -i "error" >nul && (
		echo =^> [%funcName%] ERROR: You have to belong to the administrators group to run wmic.>&2
		exit/b 1
	)

	for /f "skip=1 tokens=1-6" %%g in ('wmic path win32_localtime get day^,month^,year /format:table') do (
		if "%%~i"=="" goto s_done
		set _dd=0%%g
		set _mm=0%%h
		set _yyyy=%%i
	)
	:s_done

	::Pad digits with leading zeros
	set _mm=%_mm:~-2%
	set _dd=%_dd:~-2%
	set _date2=%_dd%/%_mm%/%_yyyy%
	echo =^> Function %funcName%: %_date2%

	endlocal
	goto :eof
