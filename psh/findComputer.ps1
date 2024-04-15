$myPattern = '*'+$args[0]+'*'
Get-ADComputer -Properties CanonicalName , Description , IPv4Address , OperatingSystem , ServicePrincipalNames -Filter { name -like $myPattern }
