
function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function InstallScoop {
		if( $isAdmin ) {
			if( ! (isInstalled("scoop.ps1")) ) {
				if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
				iex "& {$(irm get.scoop.sh)} -RunAsAdmin -ScoopDir $env:ProgramData\scoop"
			}
			if( ! (isInstalled("git.exe")) ) {
				scoop install -g git
			} else {
				if( ( git config --global credential.helper ) -ne "manager-core" ) {
					git config --global credential.helper manager-core
				}
			}

			if( ! (scoop bucket list | sls extras) ) { scoop bucket add extras }
			scoop bucket list
		}
	}
}
