Get-ADUser -Properties CanonicalName , Created , LastLogonDate , Enabled -Filter * -SearchBase $args[0]
