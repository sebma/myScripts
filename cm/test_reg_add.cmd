reg add "hklm\software\microsoft\windows nt\currentversion\winlogon" /v Welcome /d "sur %%computername%%" /f
reg add hkcu\environment /v prompt /t reg_expand_sz /d  [$s%%username%%$s@$s%%computername%%$s$p]$_$$$s /f
