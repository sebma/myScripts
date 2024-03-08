$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName , Created , LastLogonDate , Enabled -Filter { name -like $myPattern }
