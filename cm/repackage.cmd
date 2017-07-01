@echo off
title %~0

set zipFile=%1
set logFile=\%~n0.log
set toolsDir=D:\Exploit\tools
set dstDir=P:\Appli
setx toolsDir %toolsDir% -m
set env=%computername:~0,1%

if not defined zipFile (
	echo =^> Usage: %0 zipFile >&2
	exit/b 1
)

call %defvareur% >nul

if %computername%==DMIL2K01 (
	shasum.py -a 512 %toolsDir%\*.* > %toolsDir%\checksums.chk
	sed -i "/checksums\|.bak$/d" %toolsDir%\checksums.chk
	zip -9u %zipFile% %toolsDir%\*.* -x *.log -x *.bak -x *.txt
	echo =^> xcopy /y /d %zipFile% %dstDir%\ ...
	xcopy /y /d \Produits\tom\exit\reception_mvs.py %dstDir%\
	xcopy /y /d %zipFile% %dstDir%\
	xcopy /y /d %0 %dstDir%\
	xcopy /y /d %0 %dstDir%\%~n0.txt
	xcopy /y /d %0 P:\cm\
	xcopy /y /d %toolsDir%\*.cm P:\cm\
	xcopy /y /d %toolsDir%\*.py P:\py\
)

