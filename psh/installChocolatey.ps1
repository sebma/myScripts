
function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function InstallChocolatey {
		if( ! (isInstalled("choco.exe")) ) {
			$tls12 = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)
			[System.Net.ServicePointManager]::SecurityProtocol = $tls12

			if( ! [System.Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12) ) {
				[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
			}

			[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
			if( $isAdmin ) {
				if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) {
					sudo Set-ExecutionPolicy Bypass -Scope Process -Force
				}
				sudo iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
			}
		}
	}
}
