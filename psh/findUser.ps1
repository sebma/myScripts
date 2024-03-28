$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate -Filter { name -like $myPattern }
