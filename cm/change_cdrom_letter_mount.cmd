@echo off
set newDriveLetter=%1
if not defined newDriveLetter (
  echo =^> Usage: %0 newDriveLetter >&2
  exit/b -1
)

for /f "tokens=2-3" %%a in ('echo list volume ^| diskpart ^| find "-ROM "') do set _vol=%%a

( echo select volume %_vol% & echo assign letter=%newDriveLetter% ) | diskpart >nul
