$DC = $env:LOGONSERVER.Substring(2)
"=> LOGONSERVER = $DC"
$argc = $args.Count
if( $argc -eq 0 ) {
	$myPattern = $env:COMPUTERNAME
} else {
	$firstArg = $args[0]
	if( ! $firstArg.Contains("*") ) {
		$myPattern = '*'+$firstArg+'*'
	} elseif( $firstArg ) {
		$myPattern = $firstArg
	}
}

"=> myPattern = $myPattern"

Get-ADComputer -Server $DC -Properties CN , CanonicalName , Description , IPv4Address , lastLogon, msDS-SupportedEncryptionTypes , OperatingSystem , ServicePrincipalNames , whenCreated , whenChanged -Filter { Name -like $myPattern }

# Get-ADComputer -Server $DC -Properties CN , CanonicalName , Description , IPv4Address , lastLogon , msDS-SupportedEncryptionTypes , OperatingSystem , ServicePrincipalNames , whenCreated , whenChanged -Filter { Name -like $myPattern } | ? Name -match $myRegExp
