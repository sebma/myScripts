function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function InstallScoop {
		sudo cache on # i.e https://github.com/gerardog/gsudo#credentials-cache
		if( ! (isInstalled("scoop.ps1")) ) {
			if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) {
				sudo Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
			}
			sudo iex "& {$(irm get.scoop.sh)} -RunAsAdmin -ScoopDir $env:ProgramData\scoop"
		}
		if( ! (isInstalled("git.exe")) ) {
			sudo scoop install -g git
		} else {
			if( ( git config --global credential.helper ) -ne "manager-core" ) {
				sudo git config --global credential.helper manager-core
			}
		}

		if( ! (scoop bucket list | sls extras) ) { sudo scoop bucket add extras }
		scoop bucket list
	}
	InstallScoop
}
