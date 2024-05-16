$DC = $env:LOGONSERVER.Substring(2)
Get-ADComputer -Properties CN , CanonicalName , Description , IPv4Address -Filter * -SearchBase $args[0]
