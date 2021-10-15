# $HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
#

$tls12 = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)
[System.Net.ServicePointManager]::SecurityProtocol = $tls12

Update-Help

function osFamily {
	if( !(Test-Path variable:IsWindows) ) {
		# $IsWindows is not defined, let's define it
		$platform = [System.Environment]::OSVersion.Platform
		$IsWindows = $platform -eq "Win32NT"
		if( $IsWindows ) {
			$osFamily = "Windows"
			$IsLinux = $false
			$IsMacOS = $false
		} elseif( $platform -eq "Unix" ) {
			$osFamily = (uname -s)
			if( $osFamily -eq "Linux" -or $osFamily -eq "Darwin" ) {
				$IsLinux = $osFamily -eq "Linux"
				$IsMacOS = ! $IsLinux
			} else {
				$osFamily = "NOT_SUPPORTED"
				$IsLinux = $false
				$IsMacOS = $false
			}
		} else {
			$osFamily = "NOT_SUPPORTED"
			$IsLinux = $false
			$IsMacOS = $false
		}
		return $IsWindows, $IsLinux, $IsMacOS, $osFamily
	} else {
		#Using PSv>5.1 where these variables are already defined
		if( $IsWindows )   { $osFamily = "Windows" }
		elseif( $IsLinux ) { $osFamily = "Linux" }
		elseif( $IsMacOS ) { $osFamily = "Darwin" }
		else { $osFamily = "NOT_SUPPORTED" }
		return $osFamily
	}
}

function osVersion {
	if( $osFamily -eq "Windows" ) {
		$windowsType = (Get-WmiObject -Class Win32_OperatingSystem).ProductType
		if( $windowsType -eq 1 ) { $isWindowsWorkstation = $true } else { $isWindowsWorkstation = $false }
		$isWindowsServer = !$isWindowsWorkstation

		$osBuildNumber = [System.Environment]::OSVersion.Version.Build.ToString() 
		if( $isWindowsServer ) {
			switch( $osBuildNumber ) {
				3790 {$OSRelease = "W2K3"; Break}
				6003 {$OSRelease = "W2K8"; Break}
				7600 {$OSRelease = "W2K8R2"; Break}
				7601 {$OSRelease = "W2K8R2SP1"; Break}
				9200 {$OSRelease = "W2K12"; Break}
				9600 {$OSRelease = "W2K12R2"; Break}
				14393 {$OSRelease = "W2K16v1607"; Break}
				16229 {$OSRelease = "W2K16v1709"; Break}
				default { $OSRelease = "Not Known"; Break}
			}
		}
		else {
			switch( $osBuildNumber ) {
				2600 {$OSRelease = "XPSP3"; Break}
				3790 {$OSRelease = "XPPROx64SP2"; Break}
				6002 {$OSRelease = "Vista"; Break}
				7601 {$OSRelease = "7SP1"; Break}
				9200 {$OSRelease = "8"; Break}
				9600 {$OSRelease = "8.1"; Break}
				19042 {$OSRelease = "10"; Break}
				default { $OSRelease = "Not Known"; Break}
			}
		}
	}
	else {
		$OSRelease = (uname -r)
	}
	return $OSRelease
}

if( !(Test-Path variable:IsWindows) ) { $IsWindows, $IsLinux, $IsMacOS, $osFamily = osFamily } else { $osFamily = osFamily }

if( $IsWindows ) { $OSVersion = (osVersion) }

$dirSep = [io.path]::DirectorySeparatorChar
if( $IsWindows ) {
	Set-Alias vi "$env:ProgramFiles/Git/usr/bin/vim.exe"
	Set-Alias np notepad
	Set-Alias np1 notepad1
	Set-Alias np2 notepad2
	Set-Alias np3 notepad3
	Set-Alias yt-dl youtube-dl.exe
	function speedtestDownloadSingle { time speedtest --single --no-upload }
	function speedtestDownloadSimple { time speedtest --simple --no-upload }
	function speedtestSimple { time speedtest --simple }
	function speedtestSingle { time speedtest --single }
	if( ! (alias | select-string wget) ) { Set-Alias wget Invoke-WebRequest }

	Set-Alias  ex
	function ex{exit}

	function dirname($path) { Split-Path -Path $path }
	function basename($path) { $path.split($dirSep)[-1] }
	function cds($p){if($p -eq "-"){popd} else {pushd $p}}
	function cdh{pushd $HOME}
	function cd-{popd}
	function which($command) { (gcm $command).definition }
	function lock { rundll32.exe user32.dll,LockWorkStation }
	function windowsCaption { (gwmi -class Win32_OperatingSystem).Caption }
} elseif( $IsLinux ) {
	# TO BE DONE
} elseif( $IsMacOS ) {
	# TO BE DONE
}

$PowerShellUserConfigDIR = Split-Path $PROFILE
if( ! (Test-Path -Path "$PowerShellUserConfigDIR/seb_${osFamily}_aliases.ps1") ) {
	New-Item -Path "$PowerShellUserConfigDIR/seb_${osFamily}_aliases.ps1" -ItemType file
}
Import-Alias "$PowerShellUserConfigDIR/seb_${osFamily}_aliases.ps1"

$hostname = hostname
if( $IsLinux -or $IsMacOS ) { $username = $env:USER } elseif( $IsWindows ) { $username = $env:USERNAME }
$domain = "local"

function Prompt {
	$mywd = (pwd).path
	$mywd = $mywd.Replace( $HOME, '~' )
#	$PSHVersion = $PSVersionTable.PSVersion.ToString()
	$PSHVersion = ""+$PSVersionTable.PSVersion.Major + "." + $PSVersionTable.PSVersion.Minor
	Write-Host "$username : " -NoNewline
	Write-Host "$hostname " -NoNewline -ForegroundColor Yellow
	Write-Host "@ $domain / " -NoNewline -ForegroundColor Red
	Write-Host "$osFamily $OSRelease" -NoNewline -ForegroundColor Green
	Write-Host "PSv$PSHVersion " -NoNewline -ForegroundColor Blue
	Write-Host "$mywd>" -ForegroundColor Green
	return " "
}

function gitUpdate {
	echo "=> Updating from : "
	git config remote.origin.url
	git pull
	if( $IsLinux ){sync}
}

function ..{pushd ..}
function ...{pushd ../..}
function ....{pushd ../../..}
function .....{pushd ../../../..}
