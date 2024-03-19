Get-ADUser -Properties CanonicalName , Created , Description , LastLogonDate , Enabled -Filter * -SearchBase $args[0]
