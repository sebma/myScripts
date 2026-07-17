winget search Microsoft.PowerShell --source winget
winget show Microsoft.PowerShell --verbose | Select-String "Installer Type|Scope"
winget install --id Microsoft.PowerShell # local to the current user
if( $(winget show Microsoft.PowerShell --verbose | Select-String "Scope") ) {
	winget install --id Microsoft.PowerShell --scope machine --accept-package-agreements
}
gcm pwsh | % Source
pwsh -c "gcm pwsh | % Source"
Get-AppxPackage -AllUsers Microsoft.PowerShell
# winget install Microsoft.PowerShell --installer-type msi
