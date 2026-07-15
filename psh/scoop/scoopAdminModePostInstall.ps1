# See https://github.com/ScoopInstaller/Install#advanced-installation
function isInstalled($cmd) { return gcm "$cmd" 2>$null | % Name }

if( $IsWindows ) {
	function scoopAdminModePostInstall {
		if( (ls "$env:ProgramFiles\scoop\shims\scoop.ps1") -and -not (gcm "scoop.ps1" 2>$null | % Name) ) { 
			$env:SCOOP = "$env:ProgramFiles\scoop"
			& $env:SCOOP\shims\scoop.ps1 shim add scoop $env:SCOOP\shims\scoop.ps1
			scoop shim list scoop
		}
		if( ! (isInstalled("git.exe")) ) {
			sudo scoop install -g git
		}
		if( ( git config --global credential.helper ) -ne "manager-core" ) {
			sudo git config --global credential.helper manager-core # i.e https://github.com/ScoopInstaller/Main/blob/master/bucket/git.json
		}

		# Buckets of softwares
		'main' , 'extras' , 'nirsoft' , 'sysinternals' , 'versions' | % { if( -not ( scoop bucket list | sls Name=$_ ) ) { scoop bucket add $_ } }
		'main' , 'extras' , 'nirsoft' , 'sysinternals' , 'versions' | % { if( ! ( git config --get-all safe.directory | sls $_ ) ) { git config --add safe.directory `"$env:ProgramFiles/scoop/buckets/$_`" } }

		sudo scoop install -g psutils freetube kitty gow pshazz openssh openssl-lts-light psutils wget gsudo
  		sudo scoop reset openssl-lts-light
		sudo scoop shim rm putty plink pscp psftp peagent
		sudo -k
	}
	scoopAdminModePostInstall
}
# Si lenteurs "scoop search" cf. https://github.com/ScoopInstaller/Scoop/issues/4491#issuecomment-2605528197
# scoop config use_sqlite_cache true
