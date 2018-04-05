@echo off

echo.
echo Liste des arguments=%*
for %%f in (%*) do (
	echo.
rem  echo arg.mp3="%%~dnpf.mp3"
	echo arg=%%f
	echo.
	echo on
rem	call %arg%
)

