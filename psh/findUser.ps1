$myPattern = $args[0]
Get-ADUser -Filter { name -like $myPattern }
