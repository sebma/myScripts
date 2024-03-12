Get-NetIPAddress -AddressFamily IPv6  | select InterfaceAlias , IPAddress | Sort-Object InterfaceAlias
