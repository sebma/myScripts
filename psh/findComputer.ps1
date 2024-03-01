$myPattern = $args[0]
Get-ADComputer -Properties CanonicalName -Filter { name -like $myPattern }
