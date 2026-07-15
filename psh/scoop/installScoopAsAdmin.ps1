# See https://github.com/ScoopInstaller/Install#advanced-installation
function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function InstallScoopAsAdmin {
		$sudo config CacheMode auto # i.e https://github.com/gerardog/gsudo#credentials-cache
		if( ! (isInstalled("scoop.ps1")) ) {
			if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) {
				$sudo Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
			}
			$sudo Invoke-Expression "& {$(irm get.scoop.sh)} -RunAsAdmin -ScoopDir $env:ProgramData\scoop"
		}
		$sudo -k
	}
	InstallScoopAsAdmin
}

# AS ADMIN :
#irm get.scoop.sh -outfile 'scoop-Installer.ps1'
$env:SCOOP = "$env:ProgramFiles\scoop"
$env:SCOOP_GLOBAL = "$env:ProgramData\scoop"
[Environment]::SetEnvironmentVariable('SCOOP_GLOBAL', $env:SCOOP_GLOBAL, 'Machine')
#.\scoop-Installer.ps1 -RunAsAdmin -ScoopDir $env:SCOOP -ScoopGlobalDir $env:SCOOP_GLOBAL
#scoop bucket add extras
# AS USER :
$env:SCOOP = $env:ProgramFiles\scoop
if( ! $(gcm "scoop" 2>$null | % Name) ) { & $env:SCOOP\shims\scoop.ps1 shim add scoop $env:SCOOP\shims\scoop.ps1 }
