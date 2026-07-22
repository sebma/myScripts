@echo off
setlocal EnableDelayedExpansion
set dnsSearchList=""
for /f "tokens=3 usebackq skip=4" %%u in (`reg query hklm\system\currentcontrolset\services\tcpip\parameters /v searchlist`) do @(
  set dnsSearchList=%%u
  rem echo dnsSearchList=!dnsSearchList!
)
echo dnsSearchList=%dnsSearchList%
