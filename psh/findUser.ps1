$myPattern = '*'+$args[0]+'*'
Get-ADUser -Properties CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate, LockedOut, msDS-UserPasswordExpiryTimeComputed , PasswordExpired -Filter { name -like $myPattern } `
| select CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate, LockedOut, @{name="PasswordExpiryDate";expression={ [datetime]::fromfiletime($_."msDS-UserPasswordExpiryTimeComputed") } } , PasswordExpired
