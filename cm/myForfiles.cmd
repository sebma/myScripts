@echo off
set currPath=%cd%\
set commandToRun=%~1
if not defined commandToRun (
	echo =^> Usage: %0 ^<Command to run on each of the file in this directory and all subdirectories^>. >&2
	exit /b -1
)

setlocal enabledelayedexpansion
for /r %%F in (*) do (
	set file=%%F
	set relpath=!file:%currPath%=!
	echo =^> Running command !commandToRun! !relpath! ... >&2
	!commandToRun! !relpath!
	echo. >&2
)
endlocal
