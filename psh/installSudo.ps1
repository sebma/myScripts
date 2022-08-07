function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function InstallSudo {
		if( ! (isInstalled("gsudo.ps1")) ) {
			if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) {
				Set-ExecutionPolicy RemoteSigned -Scope Process -Force
			}
			[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
			iwr -useb https://raw.githubusercontent.com/gerardog/gsudo/master/installgsudo.ps1 | iex
		}
	}
	InstallSudo
}
