# winget list --scope user --id Microsoft.PowerShell
if ( (winget list --scope machine --id Microsoft.PowerShell --accept-source-agreements) ) {
	winget upgrade --scope machine Microsoft.PowerShell
} else {
	winget upgrade --scope user Microsoft.PowerShell
}
