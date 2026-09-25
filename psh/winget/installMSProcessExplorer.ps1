# See https://learn.microsoft.com/en-gb/powershell/scripting/install/install-powershell-on-windows#install-powershell-using-winget
winget search Microsoft.Sysinternals.ProcessExplorer --source winget
winget show Microsoft.Sysinternals.ProcessExplorer --verbose | Select-String "Installer Type|Scope"

if( $(winget show Microsoft.Sysinternals.ProcessExplorer --verbose | Select-String "Scope") ) {
	winget install --id Microsoft.Sysinternals.ProcessExplorer --scope machine --accept-package-agreements
} else {
	# local to the current user
	winget install --id Microsoft.Sysinternals.ProcessExplorer
}

winget list Microsoft.Sysinternals.ProcessExplorer
gcm pwsh | % Source
pwsh -c "gcm pwsh | % Source"
Get-AppxPackage -AllUsers Microsoft.Sysinternals.ProcessExplorer
