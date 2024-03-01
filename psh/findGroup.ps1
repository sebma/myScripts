$myPattern = $args[0]
Get-ADGroup -Properties CanonicalName -Filter { name -like $myPattern }
