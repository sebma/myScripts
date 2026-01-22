Set-PSReadlineKeyHandler -Key ctrl+d -Function DeleteCharOrExit

$SuppressDriveInit = $true # cf. https://stackoverflow.com/a/1662159

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8' # cf. https://stackoverflow.com/a/40098904

function setVariables {
	$global:openssl = "${ENV:ProgramFiles(x86)}\LogMeIn\x64\openssl.exe" # Le "openssl" package dans LogMeIn ne sais pas decrypter
	$global:USER = $ENV:USERNAME
	$global:DOMAIN = $ENV:USERDOMAIN
	$global:HOSTNAME = $ENV:COMPUTERNAME
	$global:isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	$global:KiTTY_LogDIR= "${ENV:ProgramData}/scoop/apps/kitty/current/log"
	$global:RecentDIR = "$ENV:APPDATA/Microsoft/Windows/Recent"
	$global:SendToDIR = "$ENV:APPDATA/Microsoft/Windows/SendTo"
	$global:StartupDIR = "$ENV:APPDATA/Microsoft/Windows/Start Menu/Programs/Startup"
	$global:QuickLaunchDIR = "$ENV:APPDATA/Microsoft/Internet Explorer/Quick Launch"
	$global:TaskBarDIR = "$ENV:APPDATA/Microsoft/Internet Explorer/Quick Launch/User Pinned/TaskBar"
	$ENV:DISPLAY = "localhost:0"
	$ENV:IsWindows = $IsWindows
}

setVariables

function sysinfo {
	Get-ComputerInfo CsManufacturer , CsModel
}

if( isInstalled("rg.exe") ) {
	function rgrep { rg -uu -g !.git/ @args }
}

if( isInstalled("ls.exe") ) {
	$global:ls = "ls.exe"
	#function ls { ls.exe -F @args }
	function l1 { & $ls -1F @args }
	function la { & $ls -aF @args }
	function ll { & $ls -lF @args }
	function lla { & $ls -laF @args }
	function llah { & $ls -lahF @args }
	function lld { & $ls -dlF @args }
	function llh { & $ls -lhF @args }
}

if( isInstalled("rm.exe") ) {
	function rm { rm.exe -vi @args }
}

#function source($script) {
#	if ($script) {
#		$tokens = $null
#		$errors = $null
#		$ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
#		if ($errors) {
#			Write-Error "Errors parsing script: $($errors -join ', ')"
#			return
#		}
#		$functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
#		foreach ($func in $functions) {
#			$funcName = $func.Name
#			$globalFuncBody = $func.Body.GetScriptBlock()
#			Set-Item -Path "Function:\global:$funcName" -Value $globalFuncBody
#		}
#	}
#
#	$assignments = $ast.FindAll({ $args[0] -is [AssignmentStatementAst] }, $false)
#	foreach ($assignment in $assignments) {
#		# bring the assignment to this scope
#		. ([scriptblock]::Create($assignment.ToString()))
#		foreach ($target in $assignment.GetAssignmentTargets()) {
#			# then get the value
#			$varName = $target.VariablePath.ToString()
#			$varValue = & ([scriptblock]::Create($target.ToString()))
#			# and assign it to the caller's scope
#			Set-Variable -Name $varName -Value $varValue -Scope Script
#		}
#	}
#}

function findfiles {
	$argc=$args.Count
	if ( $argc -eq 1 ) {
		$dirName = "."
		$regexp = $args[0]
	} elseif ( $argc -eq 2 ) {
		$dirName = $args[0]
		$regexp = $args[1]
	} else {
		write-warning "Usage : [dirName] regexp"
		return 1
	}

	dir -r -fo $dirName 2>$null | ? Name -match "$regexp" | % FullName
}

function host1($name, $server) {
	(nslookup $name $server 2>$null | sls -n Addresses: | sls Nom,Name,Address)[-2..-1] | Out-String -stream | % { $_.split(' ')[-1] }
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
function lsserial {
#	Get-CimInstance Win32_SerialPort | Select Name, Description, DeviceID
#	""
#	Get-WmiObject Win32_SerialPort | Select Name, Description, DeviceID
#	""
	$lptAndCom = '{4d36e978-e325-11ce-bfc1-08002be10318}'
	gwmi Win32_PNPEntity | ? ClassGuid -eq $lptAndCom | select Name, Description
	echo ""
}
function wgrep($regExp) {
	if( $regExp.Length -eq 0 ) { $regExp="." }
	Out-String -Stream | sls "$regExp"
}

if( ! (isInstalled("grep.exe")) ) {
	function grep($pattern , $file) {
		(cat $file) -match "$pattern"
	}
}

function msinfo { 
	$filename = "$ENV:COMPUTERNAME-$(get-date -f 'yyyyMMdd').nfo"
	time Start-Process -wait  -FilePath "msinfo32.exe" -ArgumentList "-nfo", $filename
}

function changeLanguage2English {
	[Threading.Thread]::CurrentThread.CurrentUICulture = 'en-UK'
	if( (Get-WinSystemLocale).Name -ne "en-UK" ) { Set-WinSystemLocale en-UK }
#	if( (Get-WinUserLanguageList).LanguageTag -ne "en-GB" ) { Set-WinUserLanguageList en-GB -Force }
}

function getSerialNumber {
	(gwmi win32_bios).SerialNumber
}

function getServiceTag {
	$manufacturer = $(gwmi win32_bios).Manufacturer
	if( $manufacturer -match "Dell" ) {
		(gwmi win32_bios).SerialNumber
	}
}

function getModelName {
	(gwmi Win32_ComputerSystem).Model
}

function osName {
	echo $(gwmi Win32_OperatingSystem).Caption
}

function getInstallDate {
	(Get-CimInstance Win32_OperatingSystem).InstallDate
	(gwmi Win32_OperatingSystem).InstallDate
	(gwmi Win32_OperatingSystem).InstallDate | % { [Management.ManagementDateTimeConverter]::ToDateTime( $_ ) }
}

function setLogonDC {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	"=> Running $FUNCNAME ..."
	$global:DC = $(Get-ADDomainController -Discover)
	$global:LogonDC = $ENV:LOGONSERVER.Substring(2)

	"=> Current DC from `"(Get-ADDomainController -Discover).Name`" is :"
	echo $DC.Name
	"=> Current LogonDC from `"`$ENV:LOGONSERVER.Substring(2)`" is :"
	echo $LogonDC
	"=> Current Site from (Get-ADDomainController -Discover).Site is :"
	echo $DC.Site
#	return
	if( ! $DC.Name.Contains( $LogonDC -replace "\d" ) ) {
#		"=> Current DC from nltest /dsgetdc:" + $ENV:USERDNSDOMAIN
#		nltest /dsgetdc:$ENV:USERDNSDOMAIN | sls DC: | % { ( $_ -split('\s+|\.') )[2].substring(2) }
#		"=> Current Site Name from `"nltest /dsgetdc:`""
#		nltest /dsgetdc: | sls Site.Name: | % { ( $_ -split('\s+|:') )[5] }

		"=> Switching the default DC to " + $LogonDC + " ..."
		$global:PSDefaultParameterValues = @{ "*-AD*:Server" = $LogonDC } # cf. https://serverfault.com/a/528834/312306
		"=> The default DC is now " + $(Get-ADDomainController).Name
	}

#	"=> List of DCs via `"nltest /dclist:`""
#	nltest /dclist:
}

function main {
	$FUNCNAME = $MyInvocation.MyCommand.Name
 	"=> Running $FUNCNAME ..."
 	$global:HISTFILE = $(Get-PSReadlineOption).HistorySavePath
 	$today = $(Get-Date -f 'yyyyMMdd')

#	setLogonDC
#	changeLanguage2English
}

main

if( isInstalled("choco") ) {
	. $profileDIR/profile.choco.ps1 # Ne peut pas etre mis dans la fonction "main", sinon les definitions seront locales
}













