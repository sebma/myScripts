$DC = $env:LOGONSERVER.Substring(2)
Get-ADGroup -Properties CanonicalName , Created , Description -Filter * -SearchBase $args[0]
