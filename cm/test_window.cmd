@echo off

title Running %~nx0 ...
set logFile=%systemdrive%\%~n0.log
set nfoFile=%systemdrive%\%computername%.nfo
set tailTool=tail.exe

set toolList=tail.exe sed.exe
setlocal enabledelayedexpansion
for %%t in (%toolList%) do (
	set tool=%%t
	!tool! -h >nul 2>&1
	set rc=!errorlevel!
	if !rc!==9009 (
		echo The !tool! tool is not present>&2
		exit/b !rc!
	)
)
endlocal

echo =^> Computing, see the log in realtime on the child window, it takes about one or two minutes...
rem type nul> %logFile%
rem.>%logFile%
start "%logFile%: System Information" %comspec% /c "mode 120,200 && tail -f %logFile%"
(
	echo %time%
	systeminfo | findstr -v -r "KB[0-9]*"  | findstr -v -c:": File 1"
	echo.
	echo %time%
	echo.
	echo %time%
	echo =^> Computing msinfo32 information into %nfoFile%, it can take 100%% of the CPU for up to 5 minutes ...
	echo =^> You can interrupt this by killing the "msinfo32.exe" process if you wish ...
::	start /w msinfo32 -nfo %nfoFile%
	echo %time%
	echo =^> Done.
) > %logFile%

echo =^> Press any key to close the log window...
echo =^> Please, send the file %logFile% and %nfoFile% to us.
pause > nul
taskkill -im %tailTool% -f
title Command Prompt
