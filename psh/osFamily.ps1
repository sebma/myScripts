function osFamily {
	if( !(Test-Path variable:IsWindows) ) {
		# $IsWindows is not defined, let's define it
		$platform = [System.Environment]::OSVersion.Platform
		$IsWindows = $platform -eq "Win32NT"
		if( $IsWindows ) {
			$osFamily = "Windows"
			$IsLinux = $false
			$IsMacOS = $false
		} elseif( $platform -eq "Unix" ) {
			$osFamily = (uname -s)
			if( $osFamily -eq "Linux" -or $osFamily -eq "Darwin" ) {
				$IsLinux = $osFamily -eq "Linux"
				$IsMacOS = ! $IsLinux
			} else {
				$osFamily = "NOT_SUPPORTED"
				$IsLinux = $false
				$IsMacOS = $false
			}
		} else {
			$osFamily = "NOT_SUPPORTED"
			$IsLinux = $false
			$IsMacOS = $false
		}
		return $IsWindows, $IsLinux, $IsMacOS, $osFamily
	} else {
		#Using PSv>5.1 where these variables are already defined
		if( $IsWindows )   { $osFamily = "Windows" }
		elseif( $IsLinux ) { $osFamily = "Linux" }
		elseif( $IsMacOS ) { $osFamily = "Darwin" }
		else { $osFamily = "NOT_SUPPORTED" }
		return $osFamily
	}
}
if( ! ( Test-Path variable:IsWindows ) ) { $IsWindows, $IsLinux, $IsMacOS, $osFamily = osFamily } else { $osFamily = osFamily }
