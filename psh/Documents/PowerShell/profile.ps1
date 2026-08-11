$SuppressDriveInit = $true # cf. https://stackoverflow.com/a/1662159/5649639
Set-PSReadlineKeyHandler -Key ctrl+d -Function DeleteCharOrExit

$dirSep = [io.path]::DirectorySeparatorChar

$beforeLastItemIndex = $MyInvocation.MyCommand.Path.Split($dirSep).Length - 2
$profileDIR = $MyInvocation.MyCommand.Path.Split($dirSep)[0..$beforeLastItemIndex] -join $dirSep
$scriptPrefix = $MyInvocation.MyCommand.Name.Split(".")[0]
$ENV:IsWindows = $IsWindows

function isInstalled($cmd) { return gcm "$cmd" 2>$null | % Name }
function dirname($path) { Split-Path -Parent -Path "$path" }

if( Test-Path $profileDIR/$scriptPrefix.common.ps1 ) { . $profileDIR/$scriptPrefix.common.ps1 }
if( Test-Path $profileDIR/$scriptPrefix.$osFamily.ps1 ) { . $profileDIR/$scriptPrefix.$osFamily.ps1 }
if( Test-Path $profileDIR/$scriptPrefix.$osFamily.network.ps1 ) { . $profileDIR/$scriptPrefix.$osFamily.network.ps1 }
if( Test-Path $profileDIR/aliases.$osFamily.ps1 ) { . $profileDIR/aliases.$osFamily.ps1 }

#if( isInstalled("openssl") ) {
#	. $profileDIR/$scriptPrefix.openssl.ps1
#}

#if( isInstalled("Connect-VIServer") ) {
#	. $profileDIR/$scriptPrefix.powercli.ps1 # VCF.PowerCLI
#}

if ( $(alias history *>$null;$?) ) { del alias:history }
function history() {
	cat  $(Get-PSReadlineOption).HistorySavePath
}

function prompt {
	$myCWD = $PWD.path
	$myCWD = $myCWD.Replace( $HOME, '~' )
	$PSHVersion = ""+$PSVersionTable.PSVersion.Major + "." + $PSVersionTable.PSVersion.Minor
	if( $isAdmin ) { Write-Host "$USER : " -NoNewline -ForegroundColor Red } else { Write-Host "$USER : " -NoNewline }
	Write-Host "[ " -NoNewline
	Write-Host "$HOSTNAME " -NoNewline -ForegroundColor Yellow
	Write-Host "@ $DOMAIN " -NoNewline -ForegroundColor Red
	#Write-Host "/ $osFamily $OSVersion " -NoNewline -ForegroundColor Green
	Write-Host "] " -NoNewline
	Write-Host "(PSv$PSHVersion) " -NoNewline
	Write-Host "$myCWD" -ForegroundColor Green
	if( $isAdmin ) { return "# " } else { return "$ " }
}

function ResetPrompt {
	# Remove any custom prompt function
	if (Test-Path Function:\prompt) {
		Remove-Item Function:\prompt -Force
	}

	# Restore the default PowerShell prompt
	function global:prompt {
		"PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
	}

	Write-Host "PowerShell prompt has been reset." -ForegroundColor Green
}
