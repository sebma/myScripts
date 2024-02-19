$myPattern = $args[0]
Get-ADGroup -Filter { name -like $myPattern }
