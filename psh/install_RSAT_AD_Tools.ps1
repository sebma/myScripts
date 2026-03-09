$osVersion = $PSVersionTable.BuildVersion.Major
if ( $osVersion -eq 10 ) {
	function install_RSAT_AD_Tools {
		sudo cache on
		sudo New-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 2
		$getWindowsCapabilityCommand = "& Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online"
		iex $getWindowsCapabilityCommand | Where-Object State -eq 'NotPresent' | Select-Object -Property name , displayname , state
		iex $getWindowsCapabilityCommand | sudo Add-WindowsCapability -Online
		iex $getWindowsCapabilityCommand | Select-Object -Property name , displayname , state
		sudo Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 0
		sudo -k
	}
}
