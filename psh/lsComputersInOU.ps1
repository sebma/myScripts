$DC = $env:LOGONSERVER.Substring(2)
Get-ADComputer -Properties CanonicalName , Description , IPv4Address -Filter * -SearchBase $args[0]
