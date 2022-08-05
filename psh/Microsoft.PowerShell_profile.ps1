# $HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
#

# Create Profile directory if not exists
if( ! ( Test-Path -Path (Split-Path "$PROFILE") ) ) { mkdir (Split-Path "$PROFILE");exit }

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

if( ! ( Test-Path variable:IsWindows ) ) { $IsWindows, $IsLinux, $IsMacOS, $osFamily = osFamily } else { $osFamily = osFamily }

if( $IsLinux -or $IsMacOS ) { 
	$username = $env:USER
	$hostname = $env:HOSTNAME
} elseif( $IsWindows ) {
	$username = $env:USERNAME
	$domain = $env:USERDOMAIN
	$hostname = $env:COMPUTERNAME
	$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

if( ! ($isAdmin) -and ( gcm sudo 2>$null ) ) {
	if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "ByPass" ) {
		sudo Set-ExecutionPolicy RemoteSigned
	}
#	sudo Update-Help
}

function osVersion {
	if( $osFamily -eq "Windows" ) {
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

if( $IsWindows ) { $OSVersion = (osVersion) }

function setAliases {
	set-alias -Scope Global yt-dl youtube-dl
	set-alias -Scope Global vi vim
	set-alias -Scope Global l ls.exe
}

setAliases 

$dirSep = [io.path]::DirectorySeparatorChar
if( $IsWindows ) {
	if( ! (Test-Path $HOME/Desktop/$env:COMPUTERNAME.nfo) ) { msinfo32 -nfo $HOME/Desktop/$env:COMPUTERNAME.nfo }

	function isInstalled($cmd) {
		return gcm "$cmd" 2>$null
	}

	if( ! (isInstalled("grep.exe")) ) {
		function grep($pattern , $file) {
			(cat $file) -match "$pattern"
		}
	}

	function InstallChocolatey {
		$tls12 = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072)
		[System.Net.ServicePointManager]::SecurityProtocol = $tls12

		if( ! [System.Net.ServicePointManager]::SecurityProtocol.HasFlag([Net.SecurityProtocolType]::Tls12) ) {
			[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
		}

		[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
		if( $isAdmin ) {
			if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "Bypass" ) { Set-ExecutionPolicy Bypass -Scope Process -Force }
			iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
		}
	}

	function InstallScoop {
		if( $isAdmin ) {
			if( ! (isInstalled("scoop.ps1")) ) {
				if( (Get-ExecutionPolicy) -ne "Unrestricted" -and (Get-ExecutionPolicy) -ne "RemoteSigned" -and (Get-ExecutionPolicy) -ne "Bypass" ) { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
				iex "& {$(irm get.scoop.sh)} -RunAsAdmin -ScoopDir $env:ProgramData\scoop"
			}
			if( ! (isInstalled("git.exe")) ) {
				scoop install -g git
			} else {
				if( ( git config --global credential.helper ) -ne "manager-core" ) {
					git config --global credential.helper manager-core
				}
			}

			if( ! (scoop bucket list | sls extras) ) { scoop bucket add extras }
			scoop bucket list
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

	if( (alias cd 2>$null | sls cd) ) { 
		del alias:cd
		function cd($dir) { if($dir -eq "-"){popd} else {pushd $dir} }
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
#		set-alias -Scope Global source . # does not work
		set-alias -Scope Global np notepad
		set-alias -Scope Global np++ notepad++
		set-alias -Scope Global nppp notepad++
		set-alias -Scope Global np1 notepad1
		set-alias -Scope Global np2 notepad2
		set-alias -Scope Global np3 notepad3
		set-alias -Scope Global reboot restart-computer
		if( ! (alias wget 2>$null | sls wget) ) { set-alias -Scope Global wget Invoke-WebRequest }
		set-alias -Scope Global  ex
	}

	SetWindowsAliases

	function ll { ls.exe -l @args }
	function lla { ls.exe -al @args }
	function lld { ls.exe -dl @args }
	function llh { ls.exe -lh @args }
	function llah { ls.exe -alh @args }
	function ex{exit}

	function csearch { choco search @args | sort }
	function clistlocal { choco list -l @args | sort }
	function coutdated { choco outdated }
	function cinfo { choco info @args | more }

	if(alias man 2>$null | sls man) {
		del alias:man
		function man { help @args | more }
	}

	function basename($path) { $path.split($dirSep)[-1] }
	function cdh {pushd $HOME}
	function cdr {pushd $HOME/AppData/Roaming/Microsoft/Windows/Recent}
	function cdsd {pushd $HOME/AppData/Roaming/Microsoft/Windows/SendTo}
	function cdst {pushd "$HOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"}
	function dirname($path) { Split-Path -Path $path }
	function getInterFaceInfos($name) { Get-NetIPAddress -InterfaceAlias $name }
#	function grepps($pattern) { Out-String -Stream | sls "$pattern" }
	function host($name, $server) { (nslookup $name $server 2>$null | sls Nom,Name,Address)[-2..-1] | Out-String -stream | foreach { $_.split(' ')[-1] } }
	function lock { rundll32.exe user32.dll,LockWorkStation }
	function logoff { shutdown -l }
#	function loopCommandThroughArgs($command) { $argc=$args.Count;for($i=0;$i -lt $argc;$i++) { $command $($args[$i]) } }
	function nocomment($file) { egrep -v "^(#|;|$)" "$file" }
	function pingps($remote) { Test-NetConnection $remote }
	function renamePC($newName) { Rename-Computer -NewName $newName }
	function runThroughArgs { $argc=$args.Count;for($i=0;$i -lt $argc;$i++) { echo "=> args[$i] = $($args[$i])"} }

	function groups {
		$argc=$args.Count
		if ( $argc -eq 0) {
			( (Get-ADUser -Identity $env:username -Properties MemberOf).memberof | Get-ADGroup ).name
		} else {
			for($i=0;$i -lt $argc;$i++) {
				echo "=> $($args[$i]) :"
				( ( Get-ADUser -Identity $($args[$i]) -Properties MemberOf ).memberof | Get-ADGroup ).name
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
	if ( $osVersion -eq 10 ) {
		function install_RSAT_AD_Tools {
			New-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 2
			$getWindowsCapabilityCommand = "& " + (Get-Command -Noun WindowsCapability | sls get).ToString() + " -Name RSAT.ActiveDirectory* -Online"
			iex $getWindowsCapabilityCommand | Select-Object -Property name , displayname , state
			iex $getWindowsCapabilityCommand | sudo Add-WindowsCapability -Online
			iex $getWindowsCapabilityCommand | Select-Object -Property name , displayname , state
			sudo Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Servicing -Name RepairContentServerSource -Type dword -Value 0
		}
	}
} elseif( $IsLinux ) {
	# TO BE DONE
} elseif( $IsMacOS ) {
	# TO BE DONE
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
	Get-NetRoute -DestinationPrefix 0.0.0.0/0
}

function defaultRouteV6 {
	Get-NetRoute -DestinationPrefix ::0/0
}

function interfaceInfo {
	$argc=$args.Count
	for($i=0;$i -lt $argc;$i++) {
		Get-NetAdapter -InterfaceIndex $($args[$i])
	}
}

function showRoutes {
#	Get-NetRoute -AddressFamily IPv4 @args | select InterfaceAlias,DestinationPrefix,NextHop,RouteMetric | findstr -v "224.0.0.0/4 /32"
	Get-NetRoute -AddressFamily IPv4 @args | select InterfaceAlias,DestinationPrefix,NextHop,RouteMetric | sls -NotMatch "224.0.0.0/4|/32"
}

function showRoutesV6 {
	Get-NetRoute -AddressFamily IPv6 @args | select InterfaceAlias,DestinationPrefix,NextHop,RouteMetric | findstr -v "fe80::/64 ff00::/8 /128"
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
#	(Get-ItemPropertyValue -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name NtpServer).split(',')[0]
	(w32tm -query -status | sls ^Source).ToString().Split()[1] + " = " + (w32tm -query -status | sls ^ID.*IP).ToString().Split()[-1].Split(')')[0]
}

function macAddr {
	(Get-NetAdapter) | select InterfaceAlias, MacAddress
}

function Prompt {
	$mywd = $PWD.path
	$mywd = $mywd.Replace( $HOME, '~' )
#	$PSHVersion = $PSVersionTable.PSVersion.ToString()
	$PSHVersion = ""+$PSVersionTable.PSVersion.Major + "." + $PSVersionTable.PSVersion.Minor
	if( $isAdmin) { Write-Host "$username : " -NoNewline -ForegroundColor Red } else { Write-Host "$username : " -NoNewline }
	Write-Host "$hostname " -NoNewline -ForegroundColor Yellow
	Write-Host "@ $domain / " -NoNewline -ForegroundColor Red
	Write-Host "$osFamily $OSRelease" -NoNewline -ForegroundColor Green
	Write-Host "PSv$PSHVersion " -NoNewline
	Write-Host "$mywd" -ForegroundColor Green
	if( $isAdmin) { return "# " } else { return "> " }
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
