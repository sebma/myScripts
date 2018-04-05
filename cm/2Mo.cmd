@echo off
setlocal
set/a value=%1/1024
if defined value set /a value/=1024
echo.%value%
endlocal
