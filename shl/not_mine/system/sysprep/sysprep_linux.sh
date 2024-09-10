#!/bin/bash
# Does the equivalent of sysprep for linux boxes to prepare them for cloning.
# Based on https://lonesysadmin.net/2013/03/26/preparing-linux-template-vms/
# For issues or updated versions of this script, browse to the following URL:
# https://gist.github.com/AfroThundr3007730/ff5229c5b1f9a018091b14ceac95aa55

AUTHOR='AfroThundr'
BASENAME="${0##*/}"
MODIFIED='20240304'
VERSION='1.8.3'

sysprep.parse_args() {
    [[ -n $1 ]] || {
        printf 'No arguments specified, use -h for help.\n'
        exit 1
    }
    while [[ -n $1 ]]; do
        if [[ $1 == -v ]]; then
            printf '%s: Version %s, updated %s by %s\n' \
                "$BASENAME" "$VERSION" "$MODIFIED" "$AUTHOR"
            shift
            [[ -n $1 ]] || exit 0
        elif [[ $1 == -h ]]; then
            printf 'Cloning preparation script for linux systems.\n\n'
            printf 'Usage: %s [-v ] (-h | -y [-b] [-l <log_file>] [-s])\n\n' \
                "$BASENAME"
            printf 'Options:\n'
            printf '  -h  Display this help text.\n'
            printf '  -b  Used for firstboot (internal).\n'
            printf '  -l  Specify log file location.\n'
            printf '  -s  Shutdown on completion.\n'
            printf '  -v  Emit version header.\n'
            printf '  -y  Confirm sysprep.\n'
            exit 0
        elif [[ $1 == -b ]]; then
            FIRSTBOOT=true
            break
        elif [[ $1 == -l ]]; then
            LOGFILE=$2
            shift 2
        elif [[ $1 == -s ]]; then
            SHUTDOWN=true
            shift
        elif [[ $1 == -y ]]; then
            CONFIRM=true
            shift
        else
            printf 'Invalid argument specified, use -h for help.\n'
            exit 1
        fi
    done
}

utils.say() {
    LOGFILE=${LOGFILE:=/var/log/sysprep.log}
    if [[ -n $LOGFILE && ! $LOGFILE == no ]]; then
        [[ -f $LOGFILE ]] || UMASK=027 /usr/bin/touch "$LOGFILE"
        printf '%s: %s\n' "$(date -u +%FT%TZ)" "$@" | tee -a "$LOGFILE"
    else
        printf '%s: %s\n' "$(date -u +%FT%TZ)" "$@"
    fi
}

sysprep.apt_purge() {
    vers=$(/usr/bin/ls -tr /boot/vmlinuz-* | /usr/bin/head -n -1 |
           /usr/bin/grep -v "$(uname -r)" | /usr/bin/cut -d- -f2-)
    for i in $vers; do
        debs+="$(echo linux-{image,headers,modules}-"$i") "
    done
    /usr/bin/apt remove -qy --purge "$debs" &> /dev/null &&
        /usr/bin/apt autoremove -qy --purge &> /dev/null
}

sysprep.firstboot() {
    utils.say 'Running sysprep first-boot setup script.'
    [[ $DEBIAN_DERIV == true ]] && {
        /usr/bin/find /etc/ssh/*key &>/dev/null || {
            utils.say 'Regenerating SSH host keys...'
            /usr/sbin/dpkg-reconfigure openssh-server
        }
    }

    [[ $HOSTNAME == CHANGEME ]] && {
        utils.say 'Regenerating hostname and rebooting...'
        /usr/bin/hostnamectl set-hostname \
            "linux-$(tr -cd '[:lower:][:digit:]' < /dev/urandom | head -c 9)"
        /usr/bin/systemctl reboot
    }

    [[ -f /var/lib/aide/aide.db.gz ]] && {
        utils.say 'Regenerating AIDE database...'
        /usr/sbin/aide --update
        /usr/bin/mv -f /var/lib/aide/aide.db{.new,}.gz
    }

    utils.say 'Sysprep firtst-boot setup complete, disabling service.'
    /usr/bin/systemctl disable sysprep-firstboot
    exit 0
}

sysprep.clean_packages() {
    utils.say 'Removing old kernels.'
    if [[ $FEDORA_DERIV == true ]]; then
        if command -v dnf &> /dev/null; then
            rpms=$(/usr/bin/dnf repoquery --installonly --latest-limit=-1)
            /usr/bin/dnf remove -qy "$rpms"
        else
            if ! command -v package-cleanup &> /dev/null; then
                /usr/bin/yum install -qy yum-utils &> /dev/null
            fi
            /usr/bin/package-cleanup -qy --oldkernels --count=1 &> /dev/null
        fi
    elif [[ $DEBIAN_DERIV == true ]]; then
        if ! command -v purge-old-kernels &> /dev/null; then
            /usr/bin/apt install -qy byobu &> /dev/null
        fi
        /usr/bin/purge-old-kernels -qy --keep 1 &> /dev/null || sysprep.apt_purge
    fi

    utils.say 'Clearing package cache.'
    if [[ $FEDORA_DERIV == true ]]; then
        /usr/bin/yum clean all -q &> /dev/null
        /usr/bin/rm -rf /var/cache/yum/*
    elif [[ $DEBIAN_DERIV == true ]]; then
        /usr/bin/apt clean &> /dev/null
        /usr/bin/rm -rf /var/cache/apt/archives/*
    fi
    return 0
}

sysprep.clean_logs() {
    utils.say 'Clearing old logs.'
    /usr/sbin/logrotate -f /etc/logrotate.conf
    /usr/bin/find /var/log -type f -regextype posix-extended -regex \
        ".*/*(-[0-9]{8}|.[0-9]|.gz)$" -delete
    /usr/bin/rm -rf /var/log/journal && /usr/bin/mkdir /var/log/journal
    /usr/bin/rm -f /var/log/dmesg.old
    /usr/bin/rm -f /var/log/anaconda/*

    utils.say 'Clearing audit logs.'
    : > /var/log/audit/audit.log
    : > /var/log/wtmp
    : > /var/log/lastlog
    : > /var/log/grubby
    return 0
}

sysprep.clean_network() {
    utils.say 'Clearing udev persistent rules.'
    /usr/bin/rm -f /etc/udev/rules.d/70*

    utils.say 'Removing MACs/UUIDs from network sripts.'
    if [[ $FEDORA_DERIV == true ]]; then
        /usr/bin/sed -ri '/^(HWADDR|UUID)=/d' \
            /etc/sysconfig/network-scripts/ifcfg-*
    elif [[ $DEBIAN_DERIV == true ]]; then
        /usr/bin/sed -ri '/^(mac-address|uuid)=/d' \
            /etc/NetworkManager/system-connections/*
    fi
    return 0
}

sysprep.clean_files() {
    utils.say 'Cleaning out temp directories.'
    /usr/bin/rm -rf /tmp/*
    /usr/bin/rm -rf /var/tmp/*
    /usr/bin/rm -rf /var/cache/*

    utils.say 'Cleaning up root home directory.'
    unset HISTFILE
    /usr/bin/rm -f /root/.bash_history
    /usr/bin/rm -f /root/anaconda-ks.cfg
    /usr/bin/rm -rf /root/.ssh/
    /usr/bin/rm -rf /root/.gnupg/
    return 0
}

sysprep.generalize() {
    utils.say 'Removing SSH host keys.'
    /usr/bin/rm -f /etc/ssh/*key*

    utils.say 'Clearing machine-id'
    : > /etc/machine-id

    utils.say 'Removing random-seed'
    /usr/bin/rm -f /var/lib/systemd/random-seed

    [[ -f /opt/McAfee/agent/bin/maconfig ]] && {
        utils.say 'Resetting McAfee Agent'
        /usr/bin/systemctl stop mcafee.ma
        command -V setenforce &>/dev/null && /usr/sbin/setenforce 0
        /opt/McAfee/agent/bin/maconfig -enforce -noguid
    }

    utils.say 'Resetting hostname.'
    /usr/bin/hostnamectl set-hostname 'CHANGEME'
    return 0
}

sysprep.setup_firstboot() {
    utils.say 'Enabling sysprep firstboot service.'
    FBSERVICE=/etc/systemd/system/sysprep-firstboot.service
    [[ -f $FBSERVICE ]] || /usr/bin/cat <<'EOF' > $FBSERVICE
[Unit]
Description=Sysprep first-boot setup tasks
[Service]
Type=simple
ExecStart=/usr/local/sbin/sysprep -y -b
[Install]
WantedBy=multi-user.target
EOF
    /usr/bin/systemctl enable sysprep-firstboot
    return 0
}

sysprep.run() {
    sysprep.parse_args "$@"

    [[ $CONFIRM == true ]] || {
        utils.say 'Confirm with -y to start sysprep.'
        exit 1
    }

    utils.say 'Beginning sysprep.'
    # shellcheck disable=SC1091
    source /etc/os-release
    if [[ $ID      =~ (fedora|rhel|centos) ||
          $ID_LIKE =~ (fedora|rhel|centos) ]]; then
        FEDORA_DERIV=true
    elif [[ $ID      =~ (debian|ubuntu|mint) ||
            $ID_LIKE =~ (debian|ubuntu|mint) ]]; then
        DEBIAN_DERIV=true
    else
        utils.say 'An unknown base linux distribution was detected.'
        utils.say 'This script works with Debian and Fedora based distros.'
        exit 1
    fi

    [[ $FIRSTBOOT == true ]] && sysprep.firstboot

    utils.say 'Stopping logging and auditing daemons.'
    /usr/bin/systemctl stop rsyslog.service
    /usr/sbin/service auditd stop

    sysprep.clean_packages

    sysprep.clean_logs

    sysprep.clean_network

    sysprep.clean_files

    sysprep.generalize

    sysprep.setup_firstboot

    utils.say 'End of sysprep.'
    [[ $SHUTDOWN == true ]] && {
        utils.say 'Shutting down the system.'
        /usr/bin/systemctl poweroff
    }
    exit 0
}

# Only execute if not being sourced
[[ ${BASH_SOURCE[0]} == "$0" ]] && sysprep.run "$@"
