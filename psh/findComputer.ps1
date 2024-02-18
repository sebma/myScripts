$myPattern = $args[0]
Get-ADComputer -Filter { name -like $myPattern }
