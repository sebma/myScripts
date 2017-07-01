@echo off

set command=%1
if not defined command (
  echo =^> Usage: %0 ^<command to find in path^>
  exit/b -1
)

call :getAppPaths %*
::echo Suite et fin. >&2

endlocal

exit/b %errorlevel%

:getAppPaths
setlocal enabledelayedexpansion
for %%a in (%*) do (
  set command=%%a
  set not_found=1
  for /f "skip=4 tokens=3,*" %%b in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\%%a.exe" /ve') do (
    set toolName=%%c
    echo !toolName!
    if defined toolName set not_found=0
  )
  if !not_found!==1 echo =^> ERROR: The command ^< !command! ^> was not_found not in the registry App Paths. >&2
)
exit /b !not_found!
goto :eof
