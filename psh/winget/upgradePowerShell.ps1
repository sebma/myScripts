# winget list --scope user --id Microsoft.PowerShell
if ( (winget list --scope machine --id Microsoft.PowerShell --accept-source-agreements) ) {
	winget upgrade --scope machine Microsoft.PowerShell
} elseif ( (winget list --scope user --id Microsoft.PowerShell --accept-source-agreements) ) {
	winget upgrade --scope user Microsoft.PowerShell
} else {
	echo "=> Microsoft.PowerShell is not installed with winget."
}
