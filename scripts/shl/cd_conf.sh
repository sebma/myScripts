#!/usr/bin/env bash

cdr_device=/dev/sr0
test -b $cdr_device && {
        echo "=> Configuration du peripherique de gravure par defaut dans les fichiers </etc/cdrdao.conf> et </etc/environment> ..."
        grep -q CDR_DEVICE /etc/environment  || echo CDR_DEVICE=$cdr_device  | sudo tee -a /etc/environment
        grep -q CDDA_DEVICE /etc/environment || echo CDDA_DEVICE=$cdr_device | sudo tee -a /etc/environment
        test -r /dev/dvd || sudo ln -v -s $cdr_device /dev/dvd

        egrep -q "write_device:|read_device:" /etc/cdrdao.conf 2>/dev/null || {
                cat <<-EOF
                #---/etc/cdrdao.conf --#
                read_device: "/dev/sr0"
                read_driver: "generic-mmc"
                read_paranoia_mode: 3
                #write_buffers: 128
                write_device: "/dev/sr0"
                write_driver: "generic-mmc-raw"
                write_speed: 16
                #cddb_server_list: "http://freedb.freedb.org:80/~cddb/cddb.cgi"
EOF
        } | sudo tee /etc/cdrdao.conf
}

gnome-session-quit
