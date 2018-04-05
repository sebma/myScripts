@echo off
title %~0

set zipFile=%1
if not defined zipFile (
	echo =^> Usage: %0 zipFilename >&2
	exit/b 1
)

set logFile=%~dpn0_%computername%.log
set tailTool=tail.exe
set pythonMSI=python-2.7.5
set python2Dir=D:\Produits\Python27
set toolsDir=D:\Exploit\tools
set env=%computername:~0,1%

setlocal enabledelayedexpansion
echo =^> Start of script %0 on server %computername% at !time! on the %date%, see the log on the child termnial window ...

%tailTool% --help >nul 2>&1 || unzip -ou %zipFile% %tailTool%

echo.> %logFile%
start "=> Running %* ..." %comspec% /c "mode 120,1000 & %tailTool% -f %logFile%" && (
	echo =^> Start of script %0 on server %computername% at !time! on the %date% ...
	unzip -oud / %zipFile%
	echo.

	path | findstr -i %toolsDir% >nul || (
		setx PATH "%PATH%;%toolsDir%" -m
		setx toolsDir %toolsDir% -m
		echo echo =^> Veuilly relance le script %0 dans une autre fenetre DOS, car cette fenetre va se fermer.
		timeout 5
		exit
	)

	shasum.py -c %toolsDir%\checksums.chk

	assoc .ppk=PuTTYPrivateKey
	ftype PuTTYPrivateKey="%%toolsDir%%\pageant.exe" "%%1"
	echo.

	assoc .py || (
		unzip -oud / %zipFile% %pythonMSI%
		start /wait msiexec -i \%pythonMSI% -promptrestart -qb! allusers=1 targetdir=%python2Dir% addlocal=all
		assoc .py=Python.File
		del \%pythonMSI%
	)

	ftype Python.File
) >> %logFile% 2>&1

if not %computername%==DMIL2K01 del %zipFile% %0

echo.
echo =^> Press any key to close the log window ...
timeout 10
echo.
taskkill -im %tailTool% -f
echo.
if exist %tailTool% del %tailTool%
echo =^> See the log in the file %logFile% .>&2

endlocal

