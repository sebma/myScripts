# See https://github.com/ScoopInstaller/Install#advanced-installation
function isInstalled($cmd) { return gcm "$cmd" 2>$null | % Name }

if( $IsWindows ) {
	function scoopUserModePostInstall {
		if( ! (gcm "scoop.ps1" 2>$null | % Name) -and (ls "$env:ProgramFiles\scoop\shims\scoop.ps1") ) { 
			# $env:SCOOP = "$env:ProgramFiles\scoop"
			# [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP)
			& $env:SCOOP\shims\scoop.ps1 shim add scoop $env:SCOOP\shims\scoop.ps1
			scoop shim list scoop
		}
		if( ! (isInstalled("git.exe")) ) {
			scoop install git -g
		}
		if( ( git config --global credential.helper ) -ne "manager-core" ) {
			git config --global credential.helper manager-core # i.e https://github.com/ScoopInstaller/Main/blob/master/bucket/git.json
		}

		# Buckets of softwares
		'main' , 'extras' , 'nirsoft' , 'versions' | % { if( ! (scoop bucket list | Out-String -Stream | sls ^$_) ) { scoop bucket add $_ } }
#		'main' , 'extras' , 'nirsoft' , 'versions' | % { git config --global --add safe.directory `"$env:ProgramFiles/scoop/buckets/$_`" }

		scoop install freetube kitty gow pshazz openssh openssl-lts-light psutils wget gsudo -g
  		scoop reset openssl-lts-light
		scoop shim rm putty plink pscp psftp peagent
	}
	scoopUserModePostInstall
}
# Si lenteurs "scoop search" cf. https://github.com/ScoopInstaller/Scoop/issues/4491#issuecomment-2605528197
# scoop config use_sqlite_cache true
