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
# winget install Microsoft.PowerShell --installer-type msi
