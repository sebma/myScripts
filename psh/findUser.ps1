$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
Get-ADUser -Server $DC -Properties CN , CanonicalName , Created , Description , EmailAddress , Enabled , LastLogonDate, LockedOut, msDS-UserPasswordExpiryTimeComputed , PasswordExpired , PasswordLastSet , PasswordNeverExpires , SamAccountName , UserPrincipalName -Filter { name -like $myPattern } `
| select CN , CanonicalName , Created , Description , DistinguishedName , EmailAddress , Enabled , LastLogonDate, LockedOut, @{name="PasswordExpiryDate";expression={ [datetime]::fromfiletime($_."msDS-UserPasswordExpiryTimeComputed") } } , PasswordExpired , PasswordLastSet , PasswordNeverExpires , SamAccountName , UserPrincipalName
