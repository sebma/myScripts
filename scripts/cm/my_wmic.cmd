@echo off

(
	WMIC PATH Win32_ComputerSystem Get DNSHostName /Value
	WMIC PATH Win32_BIOS Get Manufacturer /Value
	WMIC PATH Win32_ComputerSystemProduct Get Version /Value
	WMIC PATH Win32_ComputerSystem Get Model /Value
	WMIC PATH Win32_BIOS Get SerialNumber /Value
	WMIC PATH Win32_ComputerSystem Get UserName /Value
	WMIC PATH Win32_UserAccount where name="%username%" get FullName /value
	WMIC PATH Win32_OperatingSystem Get Caption /Value
	WMIC PATH Win32_OperatingSystem Get Version /Value
	WMIC PATH Win32_OperatingSystem Get OSArchitecture /Value
	WMIC PATH Win32_OperatingSystem Get InstallDate /Value
	WMIC PATH Win32_NetworkAdapterConfiguration where "IPEnabled=true" Get IPAddress /Value
	WMIC PATH Win32_NetworkAdapterConfiguration where "IPEnabled=true" Get MACAddress /Value
) | FIND "="
