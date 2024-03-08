$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName -Filter { name -like $myPattern }
