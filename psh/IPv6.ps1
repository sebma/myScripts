Get-NetIPInterface -ConnectionState Connected -AddressFamily IPv4 | % { Get-NetIPAddress -AddressFamily IPv6 -InterfaceAlias $_.InterfaceAlias } | select InterfaceAlias , IPAddress , PrefixLength
Get-NetIPInterface -ConnectionState Connected -AddressFamily IPv6 | % { Get-NetIPAddress -AddressFamily IPv6 -InterfaceAlias $_.InterfaceAlias } | select InterfaceAlias , IPAddress , PrefixLength , @{ Name='IPv4DefaultGateway'; Expression={ ( $_ | Get-NetIPConfiguration ).IPv4DefaultGateway.Nexthop } } | Format-Table
