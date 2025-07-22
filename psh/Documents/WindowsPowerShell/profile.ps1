$profileDIR=$(Split-Path -Parent -Path "$PROFILE")
$scriptName = $MyInvocation.MyCommand.Name
$scriptPrefix = $scriptName.Split(".")[0]

. $profileDIR/$scriptPrefix.common.ps1

# Create Profile directory if not exists
if( ! ( Test-Path -Path (Split-Path "$PROFILE") ) ) { mkdir (Split-Path "$PROFILE");exit }

$dirSep = [io.path]::DirectorySeparatorChar

function source($script) { . $script }

# sudo Update-Help

#if( ! ( Test-Path variable:IsWindows ) ) { $IsWindows, $IsLinux, $IsMacOS, $osFamily = osFamily } else { $osFamily = osFamily }

. $profileDIR/$scriptPrefix.$osFamily.ps1

. $profileDIR/aliases.$osFamily.ps1

if( isInstalled("Get-ADUser") ) {
	. $profileDIR/$scriptPrefix.AD.ps1
}

if( isInstalled("openssl") ) {
#	"=> Sourcing openssl functions ..."
	source $profileDIR/$scriptPrefix.openssl.ps1
	#. $profileDIR/$scriptPrefix.openssl.ps1
	setOpenSSLVariables
	#"=> openssl = $openssl"
}

function osVersion {
	if( $IsWindows ) {
		$windowsType = (Get-WmiObject -Class Win32_OperatingSystem).ProductType
		if( $windowsType -eq 1 ) { $isWindowsWorkstation = $true } else { $isWindowsWorkstation = $false }
		$isWindowsServer = !$isWindowsWorkstation

#		$osBuildNumber = [System.Environment]::OSVersion.Version.Build.ToString()
		$osBuildNumber = $PSVersionTable.BuildVersion.Build
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
				{$_ -ge 10240} {$OSRelease = $PSVersionTable.BuildVersion.Major; Break}
				default { $OSRelease = "Not Known"; Break}
			}
		}
	}
	else {
		$OSRelease = (uname -r)
	}
	return $OSRelease
}
$OSVersion = (osVersion)

function setAliases {
	set-alias -Scope Global yt-dl youtube-dl
	set-alias -Scope Global reboot restart-computer
	set-alias -Scope Global vi vim
	set-alias -Scope Global l ls.exe
	set-alias -Scope Global openssl "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"
}

setAliases

function setVariables {
	Set-Variable -Scope global openssl "${ENV:ProgramData}\scoop\apps\openssl-lts-light\current\bin\openssl.exe"
}

setVariables

if( $IsWindows ) {
	function iplink($iface) {
		if( $iface ) {
			Get-NetAdapter | ? InterfaceAlias -Match "$iface" | select InterfaceAlias , Status , MacAddress , MtuSize , LinkSpeed | Format-Table
		} else {
			Get-NetAdapter | select InterfaceAlias , Status , MacAddress , MtuSize , LinkSpeed | Format-Table
		}
	}
	function IPv4($iface) {
		if( $iface ) {
			Get-NetIPAddress -AddressFamily IPv4 | ? InterfaceAlias -Match "$iface" | ? { $_.InterfaceAlias -NotMatch "Bluetooth" -and $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPv4Address , PrefixLength
		} else {
			Get-NetIPAddress -AddressFamily IPv4  | ? { $_.InterfaceAlias -NotMatch "Bluetooth" -and $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPv4Address , PrefixLength
		}
	}
	function IPv6($iface) {
		if( $iface ) {
			Get-NetIPAddress -AddressFamily IPv6 | ? InterfaceAlias -Match "$iface" | ? { $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPv6Address , PrefixLength
		} else {
			Get-NetIPAddress -AddressFamily IPv6 | ? InterfaceAlias -NotMatch "Local Area Connection*" | select InterfaceAlias , IPv6Address , PrefixLength
		}
	}
	function iproute($dest) {
		if( $dest ) {
			Find-NetRoute -RemoteIPAddress $dest | Select-Object DestinationPrefix , NextHop , InterfaceAlias , ifIndex , InterfaceMetric , RouteMetric -Last 1 | Format-Table
		} else {
			Get-NetRoute -AddressFamily IPv4 | select DestinationPrefix,NextHop,InterfaceAlias,ifIndex,InterfaceMetric,RouteMetric | ? { $_.DestinationPrefix -ne "224.0.0.0/4" -and $_.DestinationPrefix -notmatch "[0-9.]*/32" } | Format-Table
		}
	}

	function netstat {
		Get-NetTCPConnection | select local*,remote*,state,OwningProcess,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | sort-object -property LocalPort | format-table | Out-String -Stream
	}

	function RegInitUser {
		if( Get-ItemProperty -path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name LaunchTo 2>$null) {
			if( (Get-ItemPropertyValue HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -name LaunchTo) -eq 2 ) {
				Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1
			}
		} else {
			New-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1
		}
		if( (Get-ItemPropertyValue "HKCU:\Control Panel\Keyboard" -name InitialKeyboardIndicators) -ne 2 ) {
			Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name InitialKeyboardIndicators -Type string -Value 2
		}
	}

	function RegInitGlobal {
		sudo Set-ItemProperty -Path "Registry::HKU\.DEFAULT\Control Panel\Keyboard" -Name InitialKeyboardIndicators -Value 2
	}

	if( $(alias cd *>$null;$?) ) { 
		del alias:cd
		function cd($dir) {
			if($dir -eq "-"){popd}
			elseif( ! $dir.Length ) {pushd ~}
			else {pushd $dir}
		}
	}

	function Set-ShortCut ($Source,$DestinationPath) {
		$WshShell = New-Object -comObject WScript.Shell
		$Shortcut = $WshShell.CreateShortcut($DestinationPath)
		$Shortcut.TargetPath = $Source
		$Shortcut.Save()
	}

	function basename($path) { $path.split($dirSep)[-1] }
	function cdh {pushd $HOME}
	function cdr {pushd $HOME/AppData/Roaming/Microsoft/Windows/Recent}
	function cdsd {pushd $HOME/AppData/Roaming/Microsoft/Windows/SendTo}
	function cdst {pushd "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"}
	function dirname($path) { Split-Path -Parent -Path $path }
	function getInterFaceInfos($name) { Get-NetIPAddress -InterfaceAlias $name }
#	function grepps($pattern) { Out-String -Stream | sls "$pattern" }
	function host1($name, $server) { (nslookup $name $server 2>$null | sls Nom,Name,Address)[-2..-1] | Out-String -stream | foreach { $_.split(' ')[-1] } }
	function lock { rundll32.exe user32.dll,LockWorkStation }
	function logoff { shutdown -l }
#	function loopCommandThroughArgs($command) { $argc=$args.Count;for($i=0;$i -lt $argc;$i++) { $command $($args[$i]) } }
	function pingps($remote) { Test-NetConnection $remote }
	function renamePC($newName) { Rename-Computer -NewName $newName }
	function runThroughArgs { $argc=$args.Count;for($i=0;$i -lt $argc;$i++) { echo "=> args[$i] = $($args[$i])"} }
	function sysinfo { Get-ComputerInfo CsManufacturer , CsModel | % { $_.CsManufacturer , $_.CsModel } }

	function host($name, $server, $type) {
		$FUNCNAME = $MyInvocation.MyCommand.Name
		$argc = $PSBoundParameters.Count
		if ( $argc -lt 1 ) {
			"=> Usage : $FUNCNAME `$name [`$server] [`$type=A]"
		} else {
			$ipv4RegExp = '^(https?://|s?ftps?://)?\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}'
			if( $name -match $ipv4RegExp ) {
				$ip = $name -Replace('https?://|s?ftps?://','') -Replace('(/|:\d+).*$','')
				#echo "=> $ip :"
				if ( $argc -eq 1 ) {
					(Resolve-DnsName $ip).NameHost
				} elseif ( $argc -eq 2 ) {
					(Resolve-DnsName -name $ip -server $server).NameHost
				} else {
					Write-Warning "=> Not supported for the moment."
				}
			}
			else {
				$fqdn = $name -Replace('https?://|s?ftps?://','') -Replace('(/|:\d+).*$','')
				#echo "=> $name :"
				if ( $argc -eq 1 ) {
					(Resolve-DnsName $fqdn).IP4Address
				} elseif ( $argc -eq 2 ) {
					(Resolve-DnsName -name $fqdn -server $server).IP4Address
				} elseif ( $argc -eq 3 ) {
					if ( $type -eq "-4" ) {
						$type = "A"
						(Resolve-DnsName -type $type -name $fqdn -server $server).IP4Address
					} elseif ( $type -eq "-6" ) {
						$type = "AAAA"
						(Resolve-DnsName -type $type -name $fqdn -server $server).IP6Address
					}
				} else {
					Write-Warning "=> Not supported for the moment."
				}
			}
		}
	}
	function printf {
		Write-Host -NoNewline @args
	}
	function readlinks {
		$argc=$args.Count
		if ( $argc -eq 0) {
			( Get-Item -Path . ).Target
		} else {
			for($i=0;$i -lt $argc;$i++) {
				printf "=> $($args[$i]) :`t"
				( Get-Item -Path $($args[$i]) ).Target
			}
		}
	}
	function speedtestDownloadSingle { time speedtest --single --no-upload }
	function speedtestDownloadSimple { time speedtest --simple --no-upload }
	function speedtestSimple { time speedtest --simple }
	function speedtestSingle { time speedtest --single }

	function tcpConnect($remote,$port) { Test-NetConnection $remote -Port $port }
	function typeOfVar($var) { ($var).GetType() | select Name, BaseType }
	function types { $argc=$args.Count;for($i=0;$i -lt $argc;$i++) { gcm $($args[$i]) } }
	function which { (types @args).definition }
	function winVersionCaption { (gwmi -class Win32_OperatingSystem).Caption }
} elseif( $IsLinux ) {
	# TO BE DONE
} elseif( $IsMacOS ) {
	# TO BE DONE
}

function findfiles {
	$regexp = $($args[0])
	dir -r -fo 2>$null | ? FullName -match "$regexp" | % FullName
}

function dis2iso {
	$argc=$args.Count
	if ( $argc -ne 2 ) {
		echo "=> Usage $scriptName isoFileName directoryPath"
		exit 1
	}
	$isoFileName = $args[0]
	$directoryPath = $args[1].TrimEnd('\').TrimEnd('/')
	echo "=> Running: mkisofs -J -R -o $isoFileName $directoryPath"
	mkisofs -J -R -o $isoFileName $directoryPath
}

$PowerShellUserProfileDIR = Split-Path $PROFILE
if( ! ( Test-Path -Path "$PowerShellUserProfileDIR/seb_${osFamily}_aliases.ps1" ) ) {
	New-Item -Path "$PowerShellUserProfileDIR/seb_${osFamily}_aliases.ps1" -ItemType file
}
Import-Alias "$PowerShellUserProfileDIR/seb_${osFamily}_aliases.ps1"

function initVars {
	$interFaceAliasName="LAN" # You have to change the name according to your interface's name
	$myInterface=(Get-NetIPAddress -InterfaceAlias $interFaceAliasName)
	$myIP=$myInterface.IPv4Address
}

function defaultRoute {
	if( $IsWindows ) { gsudo.exe netsh interface ip delete destinationcache }
	Get-NetRoute -DestinationPrefix 0.0.0.0/0 | select DestinationPrefix,NextHop,ifIndex,InterfaceAlias,InterfaceMetric,RouteMetric | Format-Table | Out-String -Stream
}

function defaultRouteV6 {
	Get-NetRoute -DestinationPrefix ::0/0 | select DestinationPrefix,NextHop,ifIndex,InterfaceAlias,InterfaceMetric,RouteMetric | Format-Table | Out-String -Stream
}

function interfaceInfo {
	$argc=$args.Count
	for($i=0;$i -lt $argc;$i++) {
		Get-NetAdapter -InterfaceIndex $($args[$i])
	}
}

function showRoutes {
	Get-NetRoute -AddressFamily IPv4 @args | select DestinationPrefix,NextHop,ifIndex,InterfaceAlias,InterfaceMetric,RouteMetric | Format-Table | Out-String -stream | sls -n "224.0.0.0/4|/32"
}

function showRoutesV6 {
	Get-NetRoute -AddressFamily IPv6 @args | select DestinationPrefix,NextHop,ifIndex,InterfaceAlias,InterfaceMetric,RouteMetric | Format-Table | Out-String -stream | sls -n "fe80::/64|ff00::/8|/128"
}

function lanIP {
	Get-NetIPAddress -AddressFamily IPv4 @args | select InterfaceAlias, IPv4Address
}

function lanIPv6 {
	Get-NetIPAddress -AddressFamily IPv6 @args | select InterfaceAlias, IPv6Address
}

function dnsServers {
	(Get-DnsClientServerAddress -AddressFamily IPv4 | where ServerAddresses).ServerAddresses | sort -u
}

function gateWay {
	( Get-NetRoute | where { $_.DestinationPrefix -eq '0.0.0.0/0' -and $_.NextHop -ne '0.0.0.0' } ).NextHop
}

function showNTPServers {
	if( $IsWindows ) {
#		(Get-ItemPropertyValue -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name NtpServer).split(',')[0]
		gpv HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers -v 1
  		gpv HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers -v 2
		(w32tm /query /status | sls "^Source:")[0].Line.Split()[1]
	}
}

function mac@($iface) {
	$argc = $PSBoundParameters.Count
	if( $argc -eq 0 ) { (Get-NetAdapter) | select InterfaceAlias, MacAddress }
	else { (Get-NetAdapter -Name $iface) | select InterfaceAlias, MacAddress }
}

function Prompt {
	$myCWD = $PWD.path
	$myCWD = $myCWD.Replace( $HOME, '~' )
	$PSHVersion = ""+$PSVersionTable.PSVersion.Major + "." + $PSVersionTable.PSVersion.Minor
	$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	if( $isAdmin) { Write-Host "$ENV:USERNAME : [ " -NoNewline -ForegroundColor Red } else { Write-Host "$ENV:USERNAME : [ " -NoNewline }
	Write-Host "$ENV:COMPUTERNAME " -NoNewline -ForegroundColor Yellow
	Write-Host "@ $ENV:USERDOMAIN " -NoNewline -ForegroundColor Red
	#Write-Host "/ $osFamily $OSVersion " -NoNewline -ForegroundColor Green
	Write-Host "] " -NoNewline
	#Write-Host "PSv$PSHVersion " -NoNewline
	Write-Host "PS $myCWD" -ForegroundColor Green
	if( $isAdmin ) { return "# " } else { return "$ " }
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

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
	Import-Module "$ChocolateyProfile"
}
