@echo off
set "sourceDIR=%~1"
set "destinationDIR=%~2"

set "sourceBaseName=%~nx1"
set "destinationDIR=%destinationDIR%\%sourceBaseName%"

set "robocopyFullOptions=/MT /MIR /r:0 /np /v /COPY:DAT"
set robocopyOptions=%robocopyFullOptions%

set "logDIR=C:\TEMP\Robocopy\Logs"
set "logFullFile=%logDIR%\%sourceBaseName%-FULL.log"
set "logFile=%logFullFile%

set "robocopyOptions=%robocopyFullOptions% /log:%logFile%"

REM set robocopyDryRUN = "/L"

echo on
robocopy %sourceDIR% %destinationDIR% %robocopyDryRUN% %robocopyOptions%
