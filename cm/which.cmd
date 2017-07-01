@echo off

set command=%~n1
if not defined command (
  echo =^> Usage: %0 ^<command to find in path^>
  exit/b -1
)

::setlocal enabledelayedexpansion

REM call :simple_which %*
call :which %~n1 %~n2 %~n3 %~n4 %~n5 %~n6 %~n7 %~n8 %~n9

endlocal

exit/b %errorlevel%
goto :eof

:which
	echo off
	set extensionList=exe com dll cpl cmd bat msc pl py rb vbs
	setlocal enabledelayedexpansion
	set not_found=1
	for %%a in (%*) do (
		for %%e in (%extensionList%) do (
			for %%c in (%%a.%%e) do (
				set command=%%c
				echo.%%~$PATH:c | findstr -i !command! && (
					set not_found=0
				)
			)
		)
	)

	exit/b !not_found!

	goto :eof

:simple_which
	set extensionList=exe com dll cpl cmd bat msc pl py rb vbs
	for %%a in (%*) do @for %%e in (%extensionList%) do @for %%c in (%%a.%%e) do @echo.%%~$PATH:c | findstr -i %%c
	goto :eof
