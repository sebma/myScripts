@echo off

set fireFoxPath=

for /f "tokens=*" %%p  in ('locate -lw firefox.exe ^| find /i /v "Documents and Settings"') do @(
  set fireFoxPath=%%p
)

if defined fireFoxPath (
  echo Lancement de "%fireFoxPath%" ...
  start "" "%fireFoxPath%" %* && exit
)
