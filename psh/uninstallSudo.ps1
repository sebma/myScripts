function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function UninstallSudo {
		if( (isInstalled("gsudo.ps1")) ) {
			# Terminate gsudo instances, just in case
			tskill gsudo

			$destdir = "$env:systemdrive\tools\apps\gsudo"
			# Remove gsudo files
			rmdir $destdir -r

			# Remove gsudo folder from PATH
			$p = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User).Replace(";$destdir", "");
			[System.Environment]::SetEnvironmentVariable('Path',$p,[System.EnvironmentVariableTarget]::User);
		}
	}
	UninstallSudo
}
