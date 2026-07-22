@echo off
set baseDir=%1
if not defined baseDir set baseDir=.
call :deleteIfEmpty %baseDir%
goto :eof

:deleteIfEmpty
	set startDir=%1
	for /r %startDir% %%F in (*) do @if %%~zF equ 0 (
		echo del %%F ...
		del %%F
	)

	exit /b
	goto :eof
