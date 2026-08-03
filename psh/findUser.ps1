$myRegExp = $args[0]
$DC = $env:LOGONSERVER.Substring(2)
# ` is used for Newline escape
Get-ADUser -Filter '*' -Server $DC -Properties CN , CanonicalName , Created , Description , EmailAddress , Enabled , LastLogonDate, LockedOut, msDS-UserPasswordExpiryTimeComputed , PasswordExpired , PasswordLastSet , PasswordNeverExpires , proxyAddresses , SamAccountName , UserPrincipalName `
| select CN , CanonicalName , Created , Description , DistinguishedName , EmailAddress , Enabled , LastLogonDate, LockedOut, @{name="PasswordExpiryDate";expression={ [datetime]::fromfiletime($_."msDS-UserPasswordExpiryTimeComputed") } } , PasswordExpired , PasswordLastSet , PasswordNeverExpires , proxyAddresses , SamAccountName , UserPrincipalName | ? SamAccountName -iMatch $myRegExp
