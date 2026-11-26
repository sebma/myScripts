#!/usr/bin/env bash

set -o nounset

scriptBaseName=${0/*\//}

if [ $# -eq 0 ];then
    echo "=> Usage: $scriptBaseName version" >&2
    exit 1
fi

version=$1
if grep [0-9].[0-9] -q <<< $version;then
    installPackagesFromRepo.sh ppa:ondrej/nginx nginx
else
    echo "=> Please enter version in the form digit.digit" >&2
    exit 2
fi
