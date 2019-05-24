#!/usr/bin/env bash

xsetResolution () { 
    local output=$(\xrandr | \awk  '/^.+ connected/{print$1}')
    local oldResolution=$(\xrandr | \awk '/[0-9].*\*/{print$1}')
    echo "=> Reset current resolution command :"
    echo "xrandr --output $output --mode $oldResolution"
    if [ $# = 0 ]; then
        echo "=> Usage: $FUNCNAME XResxYRes"
        echo
        echo "=> Here are the possible resolutions :"
        \xrandr | awk '/^ +[0-9]+x[0-9]+/{printf$1" "}'
        echo
        return 1
    else
        local newResolution=$1
        if ! \xrandr | grep --color=auto -wq $newResolution; then
            echo "=> $FUNCNAME ERROR : The resolution <$newResolution> is not supported." 1>&2
            return 2
        fi
        echo "=> Setting new resolution command :"
        echo "xrandr --output $output --mode $newResolution"
        \xrandr --output $output --mode $newResolution
    fi
}

xsetResolution "$@"
lxrandr || xfce4-display-settings &
