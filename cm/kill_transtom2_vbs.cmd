@echo off

set processList=trans_tom_eur1.vbs trans_tom_eur2.vbs

setlocal enabledelayedexpansion
for %%p in (%processList%) do @(
	set processName=%%p
	wmic process where "commandline like '%%!processName!%%'" delete
	timeout 1
)

endlocal

pause
