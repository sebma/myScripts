@echo off
if "%1"=="" (
  echo Usage: %0 "<dns search list>"
  exit/b 1
)
setlocal EnableDelayedExpansion
set dnsSearchList=""
for /f "tokens=3 usebackq skip=4" %%u in (`reg query hklm\system\currentcontrolset\services\tcpip\parameters /v searchlist`) do @(
  set dnsSearchList=%%u
  rem echo dnsSearchList=!dnsSearchList!
)

set dnsSearchList=%dnsSearchList%,%*

echo reg add hklm\system\currentcontrolset\services\tcpip\parameters /v searchlist /t REG_SZ /d %dnsSearchList% /f
reg add hklm\system\currentcontrolset\services\tcpip\parameters /v searchlist /t REG_SZ /d %dnsSearchList% /f
