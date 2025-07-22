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

if( isInstalled("openssl") ) {
	"=> Sourcing openssl functions ..."
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
	Set-PSReadlineKeyHandler -Key ctrl+d -Function DeleteCharOrExit
	if ( $(alias history *>$null;$?) ) { del alias:history }
	function history($regExp) {
		if( $regExp.Length -eq 0 ) { $regExp="." }
		Get-Content (Get-PSReadlineOption).HistorySavePath | ? { $_ -match "$regExp" }
	}

 	function lastBoot {
		Get-CimInstance -ClassName Win32_OperatingSystem | Select CSName , LastBootUpTime
	}
	function lastBoots($nbBoots) {
		if ( $nbBoots ) {
			Get-WinEvent -LogName System | ? Id -eq 6005 | select -f $nbBoots
		} else {
			Get-WinEvent -LogName System | ? Id -eq 6005
		}
	}


	if ( $(alias ip *>$null;$?) ) { del alias:ip }
	set-alias ipa ipv4
 	set-alias ipl iplink
	set-alias mac@ iplink
 	set-alias ipr iproute
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
	function sdiff {
		$argc=$args.Count
		if ( $argc -eq 2 ) {
			diff $(cat $args[0]) $(cat $args[1])
		}
	}

	"=> Current DC from Get-ADDomainController is : "
	$DC = (Get-ADDomainController -Discover).Name
 	echo $DC
 	"=> Current Site from (Get-ADDomainController -Discover).Site is :"
	(Get-ADDomainController -Discover).Site

	"=> Current DC from `"nltest /dsgetdc:`""
	nltest /dsgetdc: | sls DC: | % { ( $_ -split('\s+|\.') )[2].substring(2) }
	"=> Current Site Name from `"nltest /dsgetdc:`""
	nltest /dsgetdc: | sls Site.Name: | % { ( $_ -split('\s+|:') )[5] }
	"=> List of DCs via `"nltest /dclist:`""
	nltest /dclist:

	$LogonDC = $ENV:LOGONSERVER.Substring(2)
	if( ! $DC.Contains( $LogonDC -replace "\d" ) ) {
		"=> Switching the default DC to " + $LogonDC + " ..."
		$PSDefaultParameterValues = @{ "*-AD*:Server" = $LogonDC } # cf. https://serverfault.com/a/528834/312306
		"=> The default DC is now " + (Get-ADDomainController).Name
	}

	function nocomment {
		sls -n "^\s*(#|$|;|//)" @args | % Line
	}
 
	function netstat {
		Get-NetTCPConnection | select local*,remote*,state,OwningProcess,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | sort-object -property LocalPort | format-table | Out-String -Stream
	}

	function time {
		# See https://github.com/lukesampson/psutils/blob/master/time.ps1
		Set-StrictMode -Off;

		# see http://stackoverflow.com/a/3513669/87453
		$cmd, $args = $args
		$args = @($args)
		$sw = [diagnostics.stopwatch]::startnew()
		& $cmd @args
		$sw.stop()

		"$($sw.elapsed)"
	}

	function viewPubKey($pubKey) {
		& $openssl pkey -text -noout -in $pubKey
	}

	function openCsr {
		& $openssl req -noout -in @args
	}

	function viewCsr {
		openCsr @args -text
	}

	function viewCsrSummary {
		openCsr @args -subject -nameopt multiline
	}

	function openCert {
		& $openssl x509 -notext -noout -in @args
	}

	function viewCert {
		openCert @args -text
	}

	function viewCertSummary {
		openCert @args -subject -issuer -dates -ocsp_uri -nameopt multiline
	}

	function viewFullCert($cert) {
		& $openssl crl2pkcs7 -nocrl -certfile $cert | openssl pkcs7 -noout -text -print_certs
	}

	function viewFullCertSummary($cert) {
		viewFullCert($cert) | sls "CN|Not"
	}

	function openP12 {
		& $openssl pkcs12 -noenc -in @args
	}

	function der2PEM($derFile, $pemFile) {
		& $openssl x509 -in $derFile -outform PEM -out $pemFile
	}

	function pem2DER($pemFile , $derFile ) {
		& $openssl x509 -in $pemFile -outform DER -out $derFile
	}

	function pem2P12($pemFile, $CAfile, $pemKey , $p12File ) {
		& $openssl pkcs12 -in $pemFile -CAfile $CAfile -inkey $pemKey -export -out $p12File
	}

	function p12ToPEM($p12File, $pemFile) {
#		$ext = ls $p12File | % Extension
#		$pemFile = $p12File.replace( $ext , ".pem" )
		& $openssl pkcs12 -noenc -in $p12File -out $pemFile
	}

	function pfx2PEM($pfxFile, $pemFile) {
#		$ext = ls $pfxFile | % Extension
#		$pemFile = $pfxFile.replace( $ext , ".pem" )
		& $openssl pkcs12 -noenc -in $pfxFile -out $pemFile
	}

	function pfx2PKEY($pfxFile, $pkeyFile) {
	#	$ext = ls $pfxFile | % Extension
	#	$pemFile = $pfxFile.replace( $ext , ".pem" )
		& $openssl pkcs12 -nocerts -nodes -in $pfxFile -out "$pkeyFile.new"
		& $openssl pkey   -in "$pkeyFile.new" -out $pkeyFile
		remove-item "$pkeyFile.new"
	}

	function viewP12 {
		openP12 @args | openssl x509 -noout -text
	}

	function viewP12Summary {
		openP12 @args | openssl x509 -noout -subject -issuer -dates -nameopt multiline
	}

	function msinfo { msinfo32.exe -nfo "$env:COMPUTERNAME-$(get-date -f "yyyyMMdd").nfo" }

	if( ! (Test-Path $HOME/Desktop/$env:COMPUTERNAME.nfo) ) { msinfo32 -nfo $HOME/Desktop/$env:COMPUTERNAME.nfo }

	if( ! (isInstalled("grep.exe")) ) {
		function grep($pattern , $file) {
			(cat $file) -match "$pattern"
		}
	}

	function changeLanguage2English {
		[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-UK'
		if( (Get-WinSystemLocale).Name -ne "en-UK" ) { Set-WinSystemLocale en-UK }
#		if( (Get-WinUserLanguageList).LanguageTag -ne "en-GB" ) { Set-WinUserLanguageList en-GB -Force }
	}

	changeLanguage2English

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

	function SetWindowsAliases {
		set-alias -Scope Global np notepad
		set-alias -Scope Global id whoisUSER
		set-alias -Scope Global np notepad
		set-alias -Scope Global np++ notepad++
		set-alias -Scope Global nppp notepad++
		set-alias -Scope Global np1 notepad1
		set-alias -Scope Global np2 notepad2
		set-alias -Scope Global np3 notepad3
		set-alias -Scope Global reboot restart-computer
		if( ! (alias wget 2>$null | sls wget) ) { set-alias -Scope Global wget Invoke-WebRequest }
		set-alias -Scope Global more less  		
	}

	SetWindowsAliases


	if(alias man 2>$null | sls man) {
		del alias:man
		function man { help @args | less }
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
	function nocomment($file) { egrep -v "^(#|;|$)" "$file" }
	function pingps($remote) { Test-NetConnection $remote }
	function renamePC($newName) { Rename-Computer -NewName $newName }
	function runThroughArgs { $argc=$args.Count;for($i=0;$i -lt $argc;$i++) { echo "=> args[$i] = $($args[$i])"} }
	function sysinfo { Get-ComputerInfo CsManufacturer , CsModel | % { $_.CsManufacturer , $_.CsModel } }

	function groups {
		$argc=$args.Count
		if ( $argc -eq 0) {
			( (Get-ADUser -Identity $env:username -Properties MemberOf).memberof | Get-ADGroup ).name | sort
		} else {
			for($i=0;$i -lt $argc;$i++) {
				echo "=> Memberships of $($args[$i]) :"
				( ( Get-ADUser -Identity $($args[$i]) -Properties MemberOf ).memberof | Get-ADGroup ).name | sort
			}
		}
	}
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
	function lsgroup {
		$argc=$args.Count
		if ( $argc -gt 0) {
			for($i=0;$i -lt $argc;$i++) {
				echo "=> Members of group $($args[$i]) :"
				(Get-ADGroupMember $args[$i]).SamAccountName | sort
			}
		}
	}
	function showSID { (whoisUSER @args).sid.value }
	function whoisSID { (whoisUSER @args).SamAccountName }
	function whoisUSER {
		$argc=$args.Count
		if ( $argc -eq 0) {
			Get-ADUser -Identity $env:username -Properties AccountLockoutTime , BadLogonCount , Created , LastBadPasswordAttempt , PasswordLastSet
		} else {
			for($i=0;$i -lt $argc;$i++) {
				echo "=> $($args[$i]) :"
				Get-ADUser -Identity $($args[$i]) -Properties AccountLockoutTime , BadLogonCount , Created , LastBadPasswordAttempt, PasswordLastSet
			}
		}
	}
	function showOUOfComputer {
		$argc=$args.Count
		if ( $argc -eq 0) {
			Get-ADComputer -Identity $env:COMPUTERNAME -Properties DistinguishedName,LastKnownParent,MemberOf | Out-String -Stream | sls DistinguishedName,LastKnownParent,MemberOf
		} else {
			for($i=0;$i -lt $argc;$i++) {
				echo "=> $($args[$i]) :"
				Get-ADComputer -Identity $($args[$i]) -Properties DistinguishedName,LastKnownParent,MemberOf | Out-String -Stream | sls DistinguishedName,LastKnownParent,MemberOf
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
