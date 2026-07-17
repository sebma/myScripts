winget search Microsoft.PowerShell --source winget
winget show Microsoft.PowerShell --verbose | Select-String "Installer Type|Scope"
winget install --id Microsoft.PowerShell # local to the current user
if( $(winget show Microsoft.PowerShell --verbose | Select-String "Scope") ) {
	winget install --id Microsoft.PowerShell --scope machine --accept-package-agreements
}
