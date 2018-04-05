@echo off
set programexec=%~1
set programpath=%~dp1\
set programname=%~nx1
::echo programexec=%programexec%
::echo programpath=%programpath%
::echo programname=%programname%
::reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%programname%" /f /ve /t REG_SZ /d "%programexec%"
::reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%programname%" /f /v Path /t REG_SZ /d "%programpath%"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%programname%" /f /ve /t REG_SZ /d "%programexec%"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\%programname%" /f /v Path /t REG_SZ /d "%programpath%"
