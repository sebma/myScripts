function osVersion {
	if( $IsWindows ) {
		$windowsType = (Get-WmiObject -Class Win32_OperatingSystem).ProductType
		if( $windowsType -eq 1 ) { $isWindowsWorkstation = $true } else { $isWindowsWorkstation = $false }
		$isWindowsServer = !$isWindowsWorkstation

#		$osBuildNumber = [System.Environment]::OSVersion.Version.Build.ToString()
		$osBuildNumber = $PSVersionTable.BuildVersion.Build
		if( $isWindowsServer ) {
			switch( $osBuildNumber ) {
				3790 {$OSRelease = "W2K3"; Break}
				6003 {$OSRelease = "W2K8"; Break}
				7600 {$OSRelease = "W2K8R2"; Break}
				7601 {$OSRelease = "W2K8R2SP1"; Break}
				9200 {$OSRelease = "W2K12"; Break}
				9600 {$OSRelease = "W2K12R2"; Break}
				14393 {$OSRelease = "W2K16v1607"; Break}
				16229 {$OSRelease = "W2K16v1709"; Break}
				default { $OSRelease = "Not Known"; Break}
			}
		}
		else {
			switch( $osBuildNumber ) {
				2600 {$OSRelease = "XPSP3"; Break}
				3790 {$OSRelease = "XPPROx64SP2"; Break}
				6002 {$OSRelease = "Vista"; Break}
				7601 {$OSRelease = "7SP1"; Break}
				9200 {$OSRelease = "8"; Break}
				9600 {$OSRelease = "8.1"; Break}
				{$_ -ge 10240} {$OSRelease = $PSVersionTable.BuildVersion.Major; Break}
				default { $OSRelease = "Not Known"; Break}
			}
		}
	}
	else {
		$OSRelease = (uname -r)
	}
	return $OSRelease
}
$OSVersion = (osVersion)
