@echo off
set "sourceDIR=%~1"
set "destinationDIR=%~2"

set "sourceBaseName=%~nx1"
set "destinationDIR=%destinationDIR%\%sourceBaseName%"

set "robocopyDiffOptions=/MT /MIR /r:0 /np /v /COPY:DAT"
set robocopyOptions=%robocopyDiffOptions%

set "logDIR=C:\TEMP\Robocopy\Logs"
set "logDiffFile=%logDIR%\%sourceBaseName%-DIFF.log"
set "logFile=%logDiffFile%

set "robocopyOptions=%robocopyDiffOptions% /log:%logFile%"

REM set robocopyDryRUN = "/L"

echo on
robocopy %sourceDIR% %destinationDIR% %robocopyDryRUN% %robocopyOptions%
