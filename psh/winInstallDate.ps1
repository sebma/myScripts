([WMI]'').ConvertToDateTime( ( Get-WmiObject Win32_OperatingSystem ).InstallDate )
[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($(get-itemproperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion').InstallDate))
(Get-CimInstance -Class Win32_OperatingSystem).InstallDate
