@reg query "hkcu\software\microsoft\windows desktop search\ds" >nul 2>&1 && reg add "hkcu\software\microsoft\windows desktop search\ds" /v ShowStartSearchBand /t REG_DWORD /d 0 /f
