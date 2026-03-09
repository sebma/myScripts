$osVersion = $PSVersionTable.BuildVersion.Major
if ( $osVersion -eq 10 ) {
	function install_RSAT_AD_Tools {
		$sudo cache on
		$sudo New-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 2
		$getWindowsCapabilityCommand = "& Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online"
		Invoke-Expression $getWindowsCapabilityCommand | Where-Object State -eq 'NotPresent' | Select-Object -Property name , displayname , state
		Invoke-Expression $getWindowsCapabilityCommand | Where-Object State -eq 'NotPresent' | $sudo Add-WindowsCapability -Online
		Invoke-Expression $getWindowsCapabilityCommand | Where-Object State -eq 'NotPresent' | Select-Object -Property name , displayname , state
		$sudo Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 0
		$sudo -k
	}
}
