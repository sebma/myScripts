@echo off

set ToolsDir=\XPProTools4XPHome
if not exist %ToolsDir% mkdir %ToolsDir%
copy /y %0 %windir% >nul 2>&1 && (
  set isAdmin=true
  del %windir%\%0
) || set isAdmin=false

(
  reg query "hklm\software\microsoft\windows nt\currentversion" /v buildlab
  reg query "hklm\software\microsoft\windows nt\currentversion" /v csdversion
  reg query hklm\system\currentcontrolset\control\productoptions /v productsuite
) | findstr "buildlab csdversion productsuite"

wmic os get Caption,CSDVersion -value
echo.

ver | findstr -r "XP.*5.1.2600" >nul && (set isXP=true) || set isXP=false
reg query "hklm\software\microsoft\windows nt\currentversion" /v csdversion | find "Service Pack 3" >nul && (set isSP3=true) || set isSP3=false

::call :which systeminfo.exe >nul && (
::  systeminfo | find "Microsoft Windows XP Prof" >nul && (
call :which wmic.exe >nul && (
  wmic os get name | find "Microsoft Windows XP Prof" && (
    set isXPPro=true
    set isXPHome=false
  ) || (
    set isXPPro=false
    set isXPHome=true
  )
) || (
  set isXPPro=false
  set isXPHome=true
)
echo.

echo isXPPro=%isXPPro%
echo isXPHome=%isXPHome%
echo isAdmin=%isAdmin%
echo.

for %%t in (secedit.exe systeminfo.exe mountvol.exe diskpart.exe tasklist.exe taskkill.exe fsutil.exe shutdown.exe xcopy.exe robocopy.exe cacls.exe xcacls.exe gpresult.exe devmgmt.msc diskmgmt.msc dfrg.msc lusrmgr.msc gpedit.msc secpol.msc gpedit.dll nusrmgr.cpl) do (
  echo Tool=%%t
  if %isXPPro%==true (
    if not exist %ToolsDir%\%%t xcopy /d /y %windir%\system32\%%t %ToolsDir%\
  ) else (
    echo =^> Calling which %%t ...
    call :which %%t >nul || (
      if %isAdmin%==true xcopy /d /y %ToolsDir%\%%t %windir%\system32\
    )
  )
  echo.
)

::call :getAppPaths msconfig msinfo32

for %%a in (msconfig msinfo32) do (
  if %isXPPro%==true (
    if not exist %ToolsDir%\%%a_exe.reg reg export "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\%%a.exe" %ToolsDir%\%%a_exe.reg /nt4 >nul
  ) else (
    if %isAdmin%==true reg import %ToolsDir%\%%a_exe.reg >nul
  )
  for /f "skip=4 tokens=3,*" %%b in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\%%a.exe" /ve') do (
    echo Tool="%%c"
    if %isXPPro%==true (
      if not exist %ToolsDir%\%%a.exe xcopy /d /y "%%c" %ToolsDir%\
    ) else (
      if %isAdmin%==true (
        if not exist "%%c" xcopy /d /y %ToolsDir%\%%a.exe "%%c"
      )
    )
  )
  echo.
)

:getAppPaths
setlocal enabledelayedexpansion
for %%a in (%*) do (
  set command=%%a
  set not_found=1
  for /f "skip=4 tokens=3,*" %%b in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\%%a.exe" /ve') do (
    set toolPath=%%c
    echo !toolPath!
    if defined toolPath set not_found=0
  )
  if !not_found!==1 echo =^> ERROR: The command ^< !command! ^> was not_found not in the registry App Paths. >&2
)
exit /b !not_found!
goto :eof

:which
setlocal enabledelayedexpansion
for %%a in (%*) do (
  set command=%%a
  echo %%~$PATH:a | findstr -r "Command.*ECHO" >nul && (
    set not_found=1
    echo =^> ERROR: The command ^< !command! ^> was not found not in the path. >&2
  ) || (
    set not_found=0
    echo %%~$PATH:a
  )
)
exit /b !not_found!
goto :eof
