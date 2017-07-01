@echo off

title Running %~nx0 ...
set utf16LogFile=%~dpn0_%computername%.utf16
set logFile=%~dpn0_%computername%.out

set tailTool=tail.exe
%tailTool% -h >nul 2>&1
set rc=%errorlevel%
if "%rc%"=="9009" (
	echo The %tailTool% tool is not present>&2
	exit/b %rc%
)

REM echo =^> Showing the log file: %logFile% in real time on the child window, it takes about one or two minutes...

echo.> %logFile%
type nul> %utf16LogFile%

REM start "%logFile%: System Information" %comspec% /c "mode 120,200 && tail -f %utf16LogFile%"

echo =^> utf16LogFile = %utf16LogFile%
(
	echo =^> Basebord info. :
	wmic /append:%utf16LogFile% baseboard list brief
	echo =^> Bios info. :
	wmic /append:%utf16LogFile% bios list brief
	echo =^> CDROM info. :
	wmic /append:%utf16LogFile% cdrom list brief
	echo =^> Computer info. :
	wmic /append:%utf16LogFile% computersystem list brief
	echo =^> CPU info. :
	wmic /append:%utf16LogFile% cpu get name,socketdesignation,maxclockspeed,numberofcores,numberoflogicalprocessors
	echo =^> CSPRODUCT info. :
	wmic /append:%utf16LogFile% csproduct list brief
	rem echo =^> dcomapp info. :
	rem wmic /append:%utf16LogFile% dcomapp list brief
	echo =^> Screen info. :
	wmic /append:%utf16LogFile% desktopmonitor list brief
	echo =^> Diskdrive info. :
	wmic /append:%utf16LogFile% diskdrive list brief
	rem echo =^> Environment info. :
	rem wmic /append:%utf16LogFile% environment list brief
	echo =^> IDE Controller info. :
	wmic /append:%utf16LogFile% idecontroller list brief
	rem echo =^> IRQ Controller info. :
	rem wmic /append:%utf16LogFile% irq list brief
	echo =^> Lecteurs logiques :
	wmic /append:%utf16LogFile% logicaldisk list brief
	echo =^> Logon info. :
	wmic /append:%utf16LogFile% logon list brief
	echo =^> Memphysical info. :
	wmic /append:%utf16LogFile% memphysical list brief
	echo =^> Netuse info. :
	wmic /append:%utf16LogFile% netuse list brief
	echo =^> nic info. :
	wmic /append:%utf16LogFile% nic list brief
	echo =^> nicconfig info. :
	wmic /append:%utf16LogFile% nicconfig list brief
	rem echo =^> NTDomain info. :
	rem wmic /append:%utf16LogFile% ntdomain list brief
	echo =^> Nteventlog info. :
	wmic /append:%utf16LogFile% nteventlog list brief
	echo =^> OS info. :
	wmic /append:%utf16LogFile% os list brief
	echo =^> Pagefile info. :
	wmic /append:%utf16LogFile% pagefile
	echo =^> Partition info. :
	wmic /append:%utf16LogFile% partition list brief
	echo =^> portconnector info. :
	wmic /append:%utf16LogFile% portconnector list
	echo =^> Printer info. :
	wmic /append:%utf16LogFile% printer list brief
	echo =^> Printerconfig info. :
	wmic /append:%utf16LogFile% printerconfig list brief
	rem echo =^> printjob info. :
	rem wmic /append:%utf16LogFile% printjob list brief
	echo =^> Process info. :
	wmic /append:%utf16LogFile% process list brief
	rem echo =^> Product info. :
	rem wmic /append:%utf16LogFile% product list brief
	rem echo =^> QFE info. :
	rem wmic /append:%utf16LogFile% qfe list brief
	echo =^> Service info. :
	wmic /append:%utf16LogFile% service list brief
	echo =^> Share info. :
	wmic /append:%utf16LogFile% share list brief
	rem echo =^> softwarefeature info. :
	rem wmic /append:%utf16LogFile% softwarefeature get Caption,ProductName,Version
	echo =^> Sounddev info. :
	wmic /append:%utf16LogFile% sounddev list brief
	echo =^> Startup info. :
	wmic /append:%utf16LogFile% startup list
	rem echo =^> Sysaccount info. :
	rem wmic /append:%utf16LogFile% sysaccount list brief
	rem echo =^> Sysdriver info. :
	rem wmic /append:%utf16LogFile% sysdriver list brief
	echo =^> Systemenclosure info. :
	wmic /append:%utf16LogFile% systemenclosure list brief
	echo =^> Temperature info. :
	wmic /append:%utf16LogFile% temperature list brief
	echo =^> Timezone info. :
	wmic /append:%utf16LogFile% timezone list
	echo =^> Voltage info. :
	wmic /append:%utf16LogFile% voltage list brief
)
rem ) >> %utf16LogFile%

echo =^> Converting %utf16LogFile% to ascii ...
type %utf16LogFile% > %logFile%

REM | sed "s/ *$//;s/\x0//g" > %logFile%
REM del %utf16LogFile%
REM move %utf16LogFile% %logFile%

echo =^> Please, send the file %logFile% to us.
echo.
title Command Prompt
