$DC = $env:LOGONSERVER.Substring(2)
Get-ADGroup -Properties CN , CanonicalName , Created , Description -Filter * -SearchBase $args[0]
