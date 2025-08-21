$SuppressDriveInit = $true # cf. https://stackoverflow.com/a/1662159/5649639
Set-PSReadlineKeyHandler -Key ctrl+d -Function DeleteCharOrExit

$dirSep = [io.path]::DirectorySeparatorChar

$beforeLastItemIndex = $MyInvocation.MyCommand.Path.Split($dirSep).Length - 2
$profileDIR = $MyInvocation.MyCommand.Path.Split($dirSep)[0..$beforeLastItemIndex] -join $dirSep
$scriptPrefix = $MyInvocation.MyCommand.Name.Split(".")[0]

function isInstalled($cmd) { return gcm "$cmd" | % Name 2>$null }
function dirname($path) { Split-Path -Parent -Path "$path" }

#. $profileDIR/$scriptPrefix.common.ps1
#. $profileDIR/$scriptPrefix.$osFamily.ps1
#. $profileDIR/$scriptPrefix.$osFamily.network.ps1
#. $profileDIR/aliases.$osFamily.ps1

#if( isInstalled("openssl") ) {
#	. $profileDIR/$scriptPrefix.openssl.ps1
#}

#if( isInstalled("Connect-VIServer") ) {
#	. $profileDIR/$scriptPrefix.powercli.ps1 # VCF.PowerCLI
#}
