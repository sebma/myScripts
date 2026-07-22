@echo off
echo Before:
reg query "hklm\software\microsoft\windows nt\currentversion\winlogon" /v AllocateCDRoms
echo After:
reg add "hklm\software\microsoft\windows nt\currentversion\winlogon" /v AllocateCDRoms /t REG_SZ /d 1 /f
reg query "hklm\software\microsoft\windows nt\currentversion\winlogon" /v AllocateCDRoms
pause
