$DC = $env:LOGONSERVER.Substring(2)
"=> LOGONSERVER = $DC"

$firstArg = $args[0]
if( ! $firstArg.Contains("*") ) {
	$myPattern = '*'+$firstArg+'*'
} else {
	$myPattern = $firstArg
}

"=> myPattern = $myPattern"

Get-ADComputer -Server $DC -Properties CN , CanonicalName , Description , IPv4Address , OperatingSystem , ServicePrincipalNames -Filter { Name -like $myPattern }

# Get-ADComputer -Server $DC -Properties CN , CanonicalName , Description , IPv4Address , OperatingSystem , ServicePrincipalNames -Filter { Name -like $myPattern } | ? Name -match $myRegExp
