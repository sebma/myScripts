#!/usr/bin/env bash

xpiInfo () 
{ 
    for xpiFile
    do
        echo "=> xpiFile = $xpiFile"
        printf "em:id = "
        unzip -q -p $xpiFile install.rdf | egrep --color=auto -m1 "em:id" | awk -F "<|>" '{print$3}'
        printf "em:name = "
        unzip -q -p $xpiFile install.rdf | egrep --color=auto -m1 "em:name" | awk -F "<|>" '{print$3}'
        printf "em:version = "
        unzip -q -p $xpiFile install.rdf | egrep --color=auto -m1 "em:version" | awk -F "<|>" '{print$3}'
        echo
    done
}

xpiInfo $@
