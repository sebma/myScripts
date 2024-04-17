$DC = $env:LOGONSERVER.Substring(2)
Get-ADUser -Properties CanonicalName , Created , Description , LastLogonDate , Enabled -Filter * -SearchBase $args[0]
