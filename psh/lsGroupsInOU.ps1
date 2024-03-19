Get-ADGroup -Properties CanonicalName , Created , Description -Filter * -SearchBase $args[0]
