#!/usr/bin/env sh

set -x
time -p wget -o $(basename $0 .sh).log -N -c -nd -r -l1 -p -A jpg,jpeg,JPG,JPEG -X /wpimages/ --reject-regex th_ http://www.bibliorama.fr/ludique_ecransa.html $*
set +x
rm robots.txt
