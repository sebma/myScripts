@echo off
set processname=%1
if defined processname (
  tasklist | findstr /i %processname% && (
    ::echo =^> taskkill /f /im %processname%* ...
    taskkill /f /im %processname%*
  ) || echo =^> The process "%processname%" is not running.
)
