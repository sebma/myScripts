# See https://learn.microsoft.com/en-gb/powershell/scripting/install/install-powershell-on-windows#install-powershell-using-winget
winget search Microsoft.PowerShell --source winget
winget install --id Microsoft.PowerShell --source winget --installer-type wix
gcm pwsh | % Source
pwsh -c "gcm pwsh | % Source"
