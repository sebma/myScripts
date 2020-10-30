@wmic os get installdate
::@systeminfo | findstr -ri "date.*install|install.*date"
@powershell "([WMI]'').ConvertToDateTime((gwmi Win32_OperatingSystem).InstallDate)"
@powershell "[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($(gp 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').InstallDate))"
