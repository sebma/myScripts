$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName , Created , Description , LastLogonDate , Enabled -Filter { name -like $myPattern }
