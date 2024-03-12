$myPattern = '*'+$args[0]+'*'
Get-ADComputer -Properties CanonicalName , IPv4Address -Filter { name -like $myPattern }
