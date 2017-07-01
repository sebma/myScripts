@echo off

set filename=%~1
if not defined filename (
	echo =^> Usage: %0 filename
	exit/b 1
)

setlocal enabledelayedexpansion
for /f "tokens=1-6 delims=." %%a in ("!filename!") do (
	set localPartner=%%b
	set field4=%%d
	set dateField=%%e
	set reqNum=%%f
	set SPN=MELNC

	echo field4 = !field4!
	set destBaseName=

	if !field4!==MDOPE (
		set destBaseName=!SPN!.!localPartner!.M6215.!reqNum!.!dateField!
	)
	if !field4!==MDRJT (
		set destBaseName=!SPN!.!localPartner!.M6216.!reqNum!.!dateField!
	)
	if !field4!==MDRPC (
		set destBaseName=!SPN!.!localPartner!.M6217.!reqNum!.!dateField!
	)
	if !field4!==MDRVB (
		set destBaseName=!SPN!.!localPartner!.M6218.!reqNum!.!dateField!
	)

	echo destBaseName = !destBaseName!
)
endlocal
