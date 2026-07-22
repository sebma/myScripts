@echo off
set user=%1
if not defined user (
  echo =^> Usage: %0 ^<user to add in the group^>. >&2
  exit /b -1
)
net localgroup Administrateurs | findstr /i %user% >nul || net localgroup Administrateurs %USERDOMAIN%\%user% /add
