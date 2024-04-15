$dest = $args[0]
Find-NetRoute -RemoteIPAddress $dest | Select-Object ifIndex , DestinationPrefix , NextHop , InterfaceAlias , RouteMetric -Last 1 | Format-Table
