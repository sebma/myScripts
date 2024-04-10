$dest = $args[0]
Find-NetRoute -RemoteIPAddress $dest | Select-Object ifIndex , InterfaceAlias , DestinationPrefix , NextHop , RouteMetric -Last 1
