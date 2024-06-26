$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
Get-ADUser -Properties CN , CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate, LockedOut, msDS-UserPasswordExpiryTimeComputed , PasswordExpired , SamAccountName , UserPrincipalName -Filter { name -like $myPattern } `
| select CN , CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate, LockedOut, @{name="PasswordExpiryDate";expression={ [datetime]::fromfiletime($_."msDS-UserPasswordExpiryTimeComputed") } } , PasswordExpired , SamAccountName , UserPrincipalName
