#!/usr/bin/env bash

connect2SSID () { 
    local ssid=$1
    test -z "$ssid" && { 
        echo "=> Please chose a connection among these :" 1>&2
        nmcli con | grep --color 802-11-wireless
        return 1
    }
    local wifiInterface=$(nmcli dev | awk '/\<wifi|802-11-wireless\>/{print$1}')
    local currentWifiSSID=$({ nmcli con status || nmcli con show --active;} 2>/dev/null | awk "/\<$wifiInterface|802-11-wireless\>/"'{print$1}')

    if [ "$currentWifiSSID" = $ssid ]; then
        echo "=> $FUNCNAME : You're already connected to <$ssid>." 1>&2
        return 2
    else
        if [ -n "$currentWifiSSID" ]; then
            nmcli con status 2> /dev/null || nmcli con show --active
        fi
    fi

    time nmcli con up id $ssid
	echo
    nmcli con status 2> /dev/null || nmcli con show --active
	echo
    time \dig @resolver1.opendns.com A myip.opendns.com +short -4 2> /dev/null || time host -4 -t A myip.opendns.com resolver1.opendns.com | awk '/\<has\>/{print$NF}'
    set +x
}

connect2SSID "$@"
