Get-ADComputer -Properties CanonicalName , IPv4Address -Filter * -SearchBase $args[0]
