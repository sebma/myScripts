Set-PSReadlineKeyHandler -Key ctrl+d -Function DeleteCharOrExit

$USER = $ENV:USERNAME
$DOMAIN = $ENV:USERDOMAIN
$HOSTNAME = $ENV:COMPUTERNAME

$SuppressDriveInit = $true # cf. https://stackoverflow.com/a/1662159

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8' # cf. https://stackoverflow.com/a/40098904

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

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
	# gin | % BiosSeralNumber
	(gwmi -class win32_bios).SerialNumber
}

function main {
	$FUNCNAME = $MyInvocation.MyCommand.Name
 	$today = $(Get-Date -f 'yyyyMMdd')
#	"=> Running $FUNCNAME ..."
#	if( ! (Test-Path $HOME/Desktop/$env:COMPUTERNAME.nfo) ) { msinfo32 -nfo $HOME/Desktop/$env:COMPUTERNAME.nfo }
	$DC = $(Get-ADDomainController -Discover)
	$LogonDC = $ENV:LOGONSERVER.Substring(2)
	if( ! $DC.Name.Contains( $LogonDC -replace "\d" ) ) {
		"=> Current DC from `"(Get-ADDomainController -Discover).Name`" is :"
		echo $DC.Name
		"=> Current Site from (Get-ADDomainController -Discover).Site is :"
		$DC.Site

		#"=> Current DC from nltest /dsgetdc:" + $ENV:USERDNSDOMAIN
		#nltest /dsgetdc:$ENV:USERDNSDOMAIN | sls DC: | % { ( $_ -split('\s+|\.') )[2].substring(2) }
		"=> Current Site Name from `"nltest /dsgetdc:`""
		nltest /dsgetdc: | sls Site.Name: | % { ( $_ -split('\s+|:') )[5] }

		"=> Switching the default DC to " + $LogonDC + " ..."
		$global:PSDefaultParameterValues = @{ "*-AD*:Server" = $LogonDC } # cf. https://serverfault.com/a/528834/312306
		"=> The default DC is now " + $(Get-ADDomainController).Name
	}

#	"=> List of DCs via `"nltest /dclist:$ENV:USERDOMAIN`""
#	nltest /dclist:$ENV:USERDOMAIN
#	"=> Current DC from `"nltest /dsgetdc:`""
#	nltest /dsgetdc: | sls DC: | % { ( $_ -split('\s+|\.') )[2].substring(2) }
#	"=> Current Site Name from `"nltest /dsgetdc:`""
#	nltest /dsgetdc: | sls Site.Name: | % { ( $_ -split('\s+|:') )[5] }
#	"=> List of DCs via `"nltest /dclist:`""
#	nltest /dclist:

	changeLanguage2English
}

#time main
main

if( isInstalled("choco") ) {
#	"=> Sourcing Chocolatey functions ..."
	. $profileDIR/profile.choco.ps1 # Ne peut pas etre mis dans la fonction "main", sinon les definitions seront locales
}






