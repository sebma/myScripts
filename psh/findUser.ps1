$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate, LockedOut, PasswordExpired -Filter { name -like $myPattern }
