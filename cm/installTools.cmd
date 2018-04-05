@echo off

set tailTool=tail.exe
set toolList=tail sed
set zipFile=%~n0.zip

call :installTools %zipFile% %toolList% || exit/b

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
	copy/y nul %windir%\system32\test >nul 2>&1 && del %windir%\system32\test && (set dstDir=%windir%\system32) || set dstDir=.
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
