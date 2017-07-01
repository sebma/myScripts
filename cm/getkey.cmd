@echo off
setlocal
call :GetProductKey sWinProdKey
echo.
echo Windows Product Key: %sWinProdKey%
goto :eof

:GetProductKey outVarName
setlocal EnableDelayedExpansion
set "sKeyChar=BCDFGHJKMPQRTVWXY2346789"
set "sRegKey=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
set "sRegVal=DigitalProductId"

for /f "tokens=3" %%i in ('reg query "%sRegKey%" /v "%sRegVal%"') do set "sHex=%%i"

set /a "n = 52"
for /l %%i in (104,2,132) do set /a "aRegValue_!n! = 0x!sHex:~%%i,2! , n += 1"

for /l %%b in (24,-1,0) do (
  set /a "c = 0 , n = %%b %% 5"
  for /l %%i in (66,-1,52) do set /a "c = (c << 8) + !aRegValue_%%i! , aRegValue_%%i = c / 24 , c %%= 24"
  for %%j in (!c!) do set "sProductKey=!sKeyChar:~%%j,1!!sProductKey!"
  if %%b neq 0 if !n!==0 set "sProductKey=-!sProductKey!"
)
endlocal &set "%~1=%sProductKey%" &goto :eof
