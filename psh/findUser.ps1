$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName,Created,LastLogonDate -Filter { name -like $myPattern }
