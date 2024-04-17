$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
Get-ADComputer -Properties CanonicalName , Description , IPv4Address , OperatingSystem , ServicePrincipalNames -Filter { name -like $myPattern }
