function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function scoopPostInstall {
		if( ! (isInstalled("git.exe")) ) {
			sudo scoop install git -g
		}
		if( ( git config --global credential.helper ) -ne "manager-core" ) {
			sudo git config --global credential.helper manager-core # i.e https://github.com/ScoopInstaller/Main/blob/master/bucket/git.json
		}

		if( ! (sudo scoop bucket list | sls extras) ) { sudo scoop bucket add extras }
		sudo scoop install freetube kitty gow pshazz openssh openssl-lts-light psutils wget gsudo -g
  		sudo scoop reset openssl-lts-light
		sudo scoop shim rm putty plink pscp psftp peagent
		sudo -k
	}
	scoopPostInstall
}
