@reg query "hklm\SOFTWARE\Microsoft\NET Framework Setup\NDP" /s | findstr /i /v "productversion fileversion" | findstr /i version
