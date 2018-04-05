@echo off
set user=%1
if not defined user set user=%username%
if not defined USERDNSDOMAIN (
	echo =^> ERROR: You are not logged from a domain controller.>&2
	for /f "skip=40 tokens=*" %%f in ('gpresult') do echo.%%f
	exit/b 1
)

::dsquery user -name %user% | dsget user -memberof

for /f "tokens=2 delims=,=" %%g in ('dsquery user -name %user% ^| dsget user -memberof') do echo %%g
echo.
for /f "tokens=2 delims=,=" %%g in ('dsquery user -name %user% ^| dsget user -memberof -expand') do echo %%g
