net stop WMPNetworkSvc
sc query WMPNetworkSvc | findstr STOPPED && start/b %windir%\system32\sysprep\sysprep.exe
