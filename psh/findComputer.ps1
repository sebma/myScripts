$myPattern = '*'+$args[0]+'*'
Get-ADComputer -Properties CanonicalName , Description , IPv4Address -Filter { name -like $myPattern }
