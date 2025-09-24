function isInstalled($cmd) { return gcm "$cmd" 2>$null }

if( $IsWindows ) {
	function UninstallSudo {
		if( (isInstalled("gsudo.ps1")) ) {
			# Terminate gsudo instances, just in case
			tskill gsudo

			$id = (New-Object -ComObject WindowsInstaller.Installer).ProductsEx("","",7) | foreach { if ($_.InstallProperty("ProductName") -like "gsudo*") {$_.ProductCode()}}
			if ($id) { & msiexec /x $id }
		}
	}
	UninstallSudo
}
