@echo off

set command=%1
if not defined command (
  echo =^> Usage: %0 ^<command to find in path^>
  exit/b -1
)

call :which %*
::echo Suite et fin. >&2

endlocal

exit/b %errorlevel%

:which
setlocal enabledelayedexpansion
for %%a in (%*) do (
  set command=%%a
  set not_found=1
  for %%p in ("%path:;=" "%") do @(
    set curr_path=%%p
    set new_path=!curr_path:"=!\!command!
    if exist !new_path! echo !new_path! && set not_found=0
  )
  if !not_found!==1 echo =^> ERROR: The command ^< !command! ^> was not_found not in the path. >&2
)
exit/b !not_found!
goto :eof
