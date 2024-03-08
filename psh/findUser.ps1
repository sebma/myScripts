$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName,Created -Filter { name -like $myPattern }
