#!/usr/bin/env sh

[ $1 ] || {
    echo "=> Usage : $(basename $0) <prefix>" >&2
#   Example : testPPTI-SSH.sh $(printf "ppti-14-3%02d " $(seq 9)
    exit 1
}

timeOut=1
nbMicro=20
tcpProtocol=ssh
for prefix
do
    for micro in $(printf "$prefix-%02d " $(seq $nbMicro))
    do
        host $micro | grep -v $micro || nc -v -z -w $timeOut $micro $tcpProtocol
    done
done
