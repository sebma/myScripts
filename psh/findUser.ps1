$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
Get-ADUser -Properties CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate, LockedOut, msDS-UserPasswordExpiryTimeComputed , PasswordExpired , SamAccountName -Filter { name -like $myPattern } `
| select CanonicalName , Created , Description, EmailAddress , Enabled , LastLogonDate, LockedOut, @{name="PasswordExpiryDate";expression={ [datetime]::fromfiletime($_."msDS-UserPasswordExpiryTimeComputed") } } , PasswordExpired , SamAccountName
