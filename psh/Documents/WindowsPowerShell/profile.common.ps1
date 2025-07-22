function osFamily {
	if( !(Test-Path variable:IsWindows) ) {
		# $IsWindows is not defined, let's define it
		$platform = [System.Environment]::OSVersion.Platform
		$IsWindows = $IsLinux = $IsMacOS = $false
		$osFamily = "not defined yet"
		$IsWindows = $platform -eq "Win32NT"
		if( $isWindows ) {
			$osFamily = "Windows"
		} elseif( $platform -eq "Unix" ) {
			$osFamily = (uname -s)
			if( $osFamily -eq "Linux") {
				$IsLinux = $true
			} elseif( $osFamily -eq "Darwin" ) {
				$IsMacOS = $true
			} else {
				$osFamily = "NOT_SUPPORTED"
			}
		} else {
			$osFamily = "NOT_SUPPORTED"
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

function pow2($a,$n) {
	return [math]::pow($a,$n)
}

function time {
	# See https://github.com/lukesampson/psutils/blob/master/time.ps1
	Set-StrictMode -Off;

	# see http://stackoverflow.com/a/3513669/87453
	$cmd, $args = $args
	$args = @($args)
	$sw = [diagnostics.stopwatch]::startnew()
	& $cmd @args
	$sw.stop()

	Write-Warning "$($sw.elapsed)"
}

function findfiles {
	$argc=$args.Count
	if ( $argc -eq 1 ) {
		$dirName = "."
		$regexp = $args[0]
	} elseif ( $argc -eq 2 ) {
		$dirName = $args[0]
		$regexp = $args[1]
	} else {
		write-warning "Usage : [dirName] regexp"
		exit 1
	}

	dir -r -fo $dirName 2>$null | ? FullName -Match "$regexp" | % FullName
}
