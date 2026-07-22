@echo off
setlocal enabledelayedexpansion
for %%f in (%*) do (
	set file=%%~f
	echo =^> file = !file!
	sed -i "s/\r//g" !file!
)
endlocal

