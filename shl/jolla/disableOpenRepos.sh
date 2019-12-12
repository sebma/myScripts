#!/usr/bin/env sh

ssu repos | awk '/openrepos/{print $2}' | xargs -rti ssu disablerepo
#ssu repos | awk '/openrepos/{print $2}' | while read openrepo; do echo "=> Disabling $openrepo ..."; ssu disablerepo $openrepo; done #Si le xargs de GNU n'est plus present
echo
ssu repos
