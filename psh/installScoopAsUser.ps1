function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function InstallScoopAsUser {
		sudo config CacheMode auto # i.e https://github.com/gerardog/gsudo#credentials-cache
		if( ! (isInstalled("scoop.ps1")) ) {
			if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) {
				Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
			}
			iwr -useb get.scoop.sh | iex
		}
		if( ! (isInstalled("git.exe")) ) {
			sudo scoop install -g git gsudo
		} else {
			if( ( git config --global credential.helper ) -ne "manager-core" ) {
				sudo git config --global credential.helper manager-core
			}
		}

		if( ! (scoop bucket list | sls extras) ) { scoop bucket add extras }
		sudo cache off
	}
	InstallScoopAsUser
}
