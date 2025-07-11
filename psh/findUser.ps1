$myPattern = '*'+$args[0]+'*'
$DC = $env:LOGONSERVER.Substring(2)
# ` is used for Newline escape
Get-ADUser -Server $DC -Properties CN , CanonicalName , Created , Description , EmailAddress , Enabled , LastLogonDate, LockedOut, msDS-UserPasswordExpiryTimeComputed , PasswordExpired , PasswordLastSet , PasswordNeverExpires , proxyAddresses , SamAccountName , UserPrincipalName -Filter { Name -like $myPattern -or (SamAccountName -like $myPattern) } `
| select CN , CanonicalName , Created , Description , DistinguishedName , EmailAddress , Enabled , LastLogonDate, LockedOut, @{name="PasswordExpiryDate";expression={ [datetime]::fromfiletime($_."msDS-UserPasswordExpiryTimeComputed") } } , PasswordExpired , PasswordLastSet , PasswordNeverExpires , proxyAddresses , SamAccountName , UserPrincipalName
