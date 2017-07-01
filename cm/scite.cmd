@echo off
set netDrive=p:
for %%f in (%netDrive%\bin\sc*exe) do set scite=%%f

start %scite% %*
