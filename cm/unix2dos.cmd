@echo off
set file=%~1
set basefile=%~dpn1
if defined file (
	echo =^> basefile = %basefile%
	( for /f "delims=" %%i in ( %file% ) do @echo %%i) > %basefile%_dos.txt
)
