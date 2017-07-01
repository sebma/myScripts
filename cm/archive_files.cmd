@echo off
setlocal enabledelayedexpansion
set pattern=RECEPTOM.KALIAC2.SDDRA.HMIL2K02
move %pattern%.* Arch\
cd Arch
set archBaseDir=.
for %%f in (!pattern!.*) do @(
	set dateFile=%%~tf
	set year=!dateFile:~6,4!
	set month=!dateFile:~3,2!
	set day=!dateFile:~0,2!
	set destDir= !archBaseDir!\!year!\!year!!month!\!year!!month!!day!
	echo destDir = !destDir!
REM	if not exist !destDir! mkdir !destDir!
	mkdir !destDir! 2>nul
	move %%f !destDir!\
)
endlocal
pause
