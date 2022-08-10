function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function InstallScoopAsAdmin {
		sudo config CacheMode auto # i.e https://github.com/gerardog/gsudo#credentials-cache
		if( ! (isInstalled("scoop.ps1")) ) {
			if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) {
				sudo Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
			}
			sudo iex "& {$(irm get.scoop.sh)} -RunAsAdmin -ScoopDir $env:ProgramData\scoop"
		}
		sudo cache off
	}
	InstallScoopAsAdmin
}
