$osVersion = $PSVersionTable.BuildVersion.Major
if ( $osVersion -eq 10 ) {
	function install_RSAT_AD_Tools {
		New-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 2
		$getWindowsCapabilityCommand = "& " + (Get-Command -Noun WindowsCapability | sls get).ToString() + " -Name RSAT.ActiveDirectory* -Online"
		iex $getWindowsCapabilityCommand | Select-Object -Property name , displayname , state
		iex $getWindowsCapabilityCommand | sudo Add-WindowsCapability -Online
		iex $getWindowsCapabilityCommand | Select-Object -Property name , displayname , state
		sudo Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 0
	}
}
