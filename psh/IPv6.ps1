Get-NetIPInterface -ConnectionState Connected -AddressFamily IPv6 | % { Get-NetIPAddress -AddressFamily IPv6 -InterfaceAlias $_.InterfaceAlias } | select InterfaceAlias , IPAddress , PrefixLength
Get-NetIPInterface -ConnectionState Connected -AddressFamily IPv6 | % { Get-NetIPAddress -AddressFamily IPv6 -InterfaceAlias $_.InterfaceAlias } | select InterfaceAlias , IPAddress , PrefixLength , @{ Name='IPv6DefaultGateway'; Expression={ ( $_ | Get-NetIPConfiguration ).IPv6DefaultGateway.Nexthop } } | Format-Table
