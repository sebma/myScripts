$myPattern = '*'+$args[0]+'*'
Get-ADComputer -Properties CanonicalName , Description , IPv4Address , ServicePrincipalNames -Filter { name -like $myPattern }
