# See https://learn.microsoft.com/en-gb/powershell/scripting/install/install-powershell-on-windows#install-powershell-using-winget
winget search Microsoft.PowerShell --source winget
winget show Microsoft.PowerShell --verbose | Select-String "Installer Type|Scope"
if( $(winget show Microsoft.PowerShell --verbose | Select-String "Scope") ) {
	winget install --id Microsoft.PowerShell --scope machine --accept-package-agreements
} else {
	# local to the current user
	winget install --id Microsoft.PowerShell
}
gcm pwsh | % Source
pwsh -c "gcm pwsh | % Source"
Get-AppxPackage -AllUsers Microsoft.PowerShell
