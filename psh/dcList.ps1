Get-ADDomainController -Filter '*' | Select Hostname , IPv4Address , OperatingSystem , Site , IsReadOnly | sort Hostname | Format-Table
