Get-NetIPAddress -AddressFamily IPv4  | select InterfaceAlias , IPAddress | Sort-Object InterfaceAlias
