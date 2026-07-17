winget search Microsoft.PowerShell --source winget
winget install --id Microsoft.PowerShell --installer-type wix
gcm pwsh | % Source
pwsh -c "gcm pwsh | % Source"
