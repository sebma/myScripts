# See https://github.com/ScoopInstaller/Install#advanced-installation
function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function scoopPostInstall {
		if( ! $(gcm "scoop" 2>$null | % Name) ) { & $env:SCOOP\shims\scoop.ps1 shim add scoop $env:SCOOP\shims\scoop.ps1 }
		if( ! (isInstalled("git.exe")) ) {
			sudo scoop install git -g
		}
		if( ( git config --global credential.helper ) -ne "manager-core" ) {
			sudo git config --global credential.helper manager-core # i.e https://github.com/ScoopInstaller/Main/blob/master/bucket/git.json
		}

		# Buckets of softwares
		'main' , 'extras' , 'nirsoft' , 'versions' | % { scoop bucket list | Out-String -Stream | sls ^$_ || scoop bucket add $_ }
#		'main' , 'extras' , 'nirsoft' , 'versions' | % { git config --global --add safe.directory `"$env:ProgramFiles/scoop/buckets/$_`" }

		sudo scoop install freetube kitty gow pshazz openssh openssl-lts-light psutils wget gsudo -g
  		sudo scoop reset openssl-lts-light
		sudo scoop shim rm putty plink pscp psftp peagent
		sudo -k
	}
	scoopPostInstall
}
