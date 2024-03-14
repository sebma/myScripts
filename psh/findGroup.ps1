$myPattern = '*'+$args[0]+'*'
Get-ADGroup -Properties CanonicalName,Created -Filter { name -like $myPattern }
