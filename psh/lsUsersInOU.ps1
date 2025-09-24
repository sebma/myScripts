$DC = $env:LOGONSERVER.Substring(2)
Get-ADUser -Properties CN , CanonicalName , Created , Description , EmailAddress , LastLogonDate , Enabled -Filter * -SearchBase $args[0]
