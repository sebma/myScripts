"=> Sourcing $scriptPrefix.$osFamily.network.ps1 functions ..."

function wanIP {
	Resolve-DnsName -name myip.opendns.com -server resolver1.opendns.com | % IPAddress
}

function lanIP {
	Get-NetIPInterface -ConnectionState Connected -AddressFamily IPv4 | % { Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $_.InterfaceAlias } | select InterfaceAlias , IPAddress , PrefixLength , @{ Name='IPv4DefaultGateway'; Expression={ ( $_ | Get-NetIPConfiguration ).IPv4DefaultGateway.Nexthop } } | Format-Table
}

function netstat {
	Get-NetTCPConnection | select local*,remote*,state,OwningProcess,@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}} | sort-object -property LocalPort | format-table | Out-String -Stream
}

function iplink($iface) {
	if( $iface ) {
		Get-NetAdapter | ? InterfaceAlias -Match "$iface" | select InterfaceAlias , Status , MacAddress , MtuSize , LinkSpeed | Format-Table
	} else {
		Get-NetAdapter | select InterfaceAlias , Status , MacAddress , MtuSize , LinkSpeed | Format-Table
	}
}
function ip($iface) {
	if( $iface ) {
		Get-NetIPAddress | ? InterfaceAlias -Match "$iface" | ? { $_.InterfaceAlias -NotMatch "Bluetooth" -and $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPAddress , PrefixLength
	} else {
		Get-NetIPAddress | ? { $_.InterfaceAlias -NotMatch "Bluetooth" -and $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPAddress , PrefixLength
	}
}
function IPv4($iface) {
	if( $iface ) {
		Get-NetIPAddress -AddressFamily IPv4 | ? InterfaceAlias -Match "$iface" | ? { $_.InterfaceAlias -NotMatch "Bluetooth" -and $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPv4Address , PrefixLength
	} else {
		Get-NetIPAddress -AddressFamily IPv4 | ? { $_.InterfaceAlias -NotMatch "Bluetooth" -and $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPv4Address , PrefixLength
	}
}
function IPv6($iface) {
	if( $iface ) {
		Get-NetIPAddress -AddressFamily IPv6 | ? InterfaceAlias -Match "$iface" | ? { $_.InterfaceAlias -NotMatch "Local Area Connection*" } | select InterfaceAlias , IPv6Address , PrefixLength
	} else {
		Get-NetIPAddress -AddressFamily IPv6 | ? InterfaceAlias -NotMatch "Local Area Connection*" | select InterfaceAlias , IPv6Address , PrefixLength
	}
}
function iproute($dest) {
	if( $dest ) {
		Find-NetRoute -RemoteIPAddress $dest | Select-Object DestinationPrefix , NextHop , InterfaceAlias , ifIndex , InterfaceMetric , RouteMetric -Last 1 | Format-Table
	} else {
		Get-NetRoute -AddressFamily IPv4 | select DestinationPrefix,NextHop,InterfaceAlias,ifIndex,InterfaceMetric,RouteMetric | ? { $_.DestinationPrefix -ne "224.0.0.0/4" -and $_.DestinationPrefix -notmatch "[0-9.]*/32" } | Format-Table
	}
}
function host($url, $server, $type) {
	$FUNCNAME = $MyInvocation.MyCommand.Name
	$argc = $PSBoundParameters.Count
	if ( $argc -lt 1 ) {
		"=> Usage : $FUNCNAME `$url [`$server] [`$type=A]"
	} else {
		$ipv4RegExp = '^(https?://|s?ftps?://)?\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}'
		if( $url -Match $ipv4RegExp ) {
			$ip = $url -Replace('https?://|s?ftps?://','') -Replace('(/|:\d+).*$','')
			if ( $argc -eq 1 ) {
				(Resolve-DnsName $ip).NameHost | sort
			} elseif ( $argc -eq 2 ) {
				(Resolve-DnsName -name $ip -server $server).NameHost | sort
			} else {
				Write-Warning "=> Not supported for the moment."
			}
		}
		else {
			$fqdn = $url -Replace('https?://|s?ftps?://','') -Replace('(/|:\d+).*$','')
			if ( $argc -eq 1 ) {
				(Resolve-DnsName $fqdn).IP4Address | sort
			} elseif ( $argc -eq 2 ) {
				(Resolve-DnsName -name $fqdn -server $server).IP4Address | sort
			} elseif ( $argc -eq 3 ) {
				if ( $type -eq "-4" ) {
					$type = "A"
					(Resolve-DnsName -type $type -name $fqdn -server $server).IP4Address | sort
				} elseif ( $type -eq "-6" ) {
					$type = "AAAA"
					(Resolve-DnsName -type $type -name $fqdn -server $server).IP6Address | sort
				} elseif ( $type -eq "-NS" ) {
					$type = "NS"
					(Resolve-DnsName -type $type -name $fqdn -server $server).NameHost | sort
				}
			} else {
				Write-Warning "=> Not supported for the moment."
			}
		}
	}
}
