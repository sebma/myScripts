function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function scoopPostInstall {
		if( ! (isInstalled("git.exe")) ) {
			sudo scoop install -g git
		}
		if( ( git config --global credential.helper ) -ne "manager-core" ) {
			sudo git config --global credential.helper manager-core # i.e https://github.com/ScoopInstaller/Main/blob/master/bucket/git.json
		}

		if( ! (sudo scoop bucket list | sls extras) ) { sudo scoop bucket add extras }
		sudo scoop install -g freetube kitty gow pshazz openssh psutils wget gsudo
		sudo scoop shim rm putty plink pscp psftp peagent
		sudo cache off
	}
	scoopPostInstall
}
