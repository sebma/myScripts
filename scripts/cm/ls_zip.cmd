@echo off

set zipfile=%~1
if not defined zipfile (
  echo =^> Usage: %0 zipFilename >&2
  pause
  exit/b 1
)

set zipfile="%~dp0%zipfile%"

set APP_HOME=D:\Produits\Appli

::Permet l'expension des variables dans les processus fils
setlocal enabledelayedexpansion

for /f "tokens=2" %%f in ('unzip -t %zipfile% ^| findstr "testing"') do @(
  echo %%f| findstr -r "[^/]$" >nul && (
    set File=%%f
    echo File = !File!
  )
)

exit/b
