Set-PSReadlineKeyHandler -Key ctrl+d -Function DeleteCharOrExit
$USER = $ENV:USERNAME
$DOMAIN = $ENV:USERDOMAIN
$HOSTNAME = $ENV:COMPUTERNAME

function rm { rm.exe -vi @args }
#function ls { ls.exe -F @args }
function l1 { ls.exe -1F @args }
function la { ls.exe -aF @args }
function ll { ls.exe -lF @args }
function lla { ls.exe -laF @args }
function llh { ls.exe -lhF @args }
function llah { ls.exe -lahF @args }

function source($script ) {
	if ($script) {
		$tokens = $null
		$errors = $null
		$ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
		if ($errors) {
			Write-Error "Errors parsing script: $($errors -join ', ')"
			return
		}
		$functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
		foreach ($func in $functions) {
			$funcName = $func.Name
			$globalFuncBody = $func.Body.GetScriptBlock()
			Set-Item -Path "Function:\global:$funcName" -Value $globalFuncBody
		}
	}
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
function wgrep($regExp) {
	if( $regExp.Length -eq 0 ) { $regExp="." }
	Out-String -Stream | sls "$regExp"
}

function msinfo { msinfo32.exe -nfo "$ENV:COMPUTERNAME-$(get-date -f "yyyyMMdd").nfo" }

function main {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	"=> Running $FUNCNAME ..."
	$DC = (Get-ADDomainController -Discover).Name
	$LogonDC = $ENV:LOGONSERVER.Substring(2)
	if( ! $DC.Contains( $LogonDC -replace "\d" ) ) {
		"=> Current DC from `"(Get-ADDomainController -Discover).Name`" is :"
		echo $DC
		#"=> Current Site from (Get-ADDomainController -Discover).Site is :"
		#(Get-ADDomainController -Discover).Site

		#"=> Current DC from nltest /dsgetdc:" + $ENV:USERDNSDOMAIN
		#nltest /dsgetdc:$ENV:USERDNSDOMAIN | sls DC: | % { ( $_ -split('\s+|\.') )[2].substring(2) }
		"=> Current Site Name from `"nltest /dsgetdc:`""
		nltest /dsgetdc: | sls Site.Name: | % { ( $_ -split('\s+|:') )[5] }

		"=> Switching the default DC to " + $LogonDC + " ..."
		$PSDefaultParameterValues = @{ "*-AD*:Server" = $LogonDC } # cf. https://serverfault.com/a/528834/312306
		"=> Default DC is now " + (Get-ADDomainController).Name
	}

	#"=> List of DCs via `"nltest /dclist:$ENV:USERDOMAIN`""
	#nltest /dclist:$ENV:USERDOMAIN
}

#time main
main
