#!/usr/bin/env sh

ssu repos | awk '/openrepos/{print $2}' | xargs -rtl ssu enablerepo
#ssu repos | awk '/openrepos/{print $2}' | while read openrepo; do echo "=> Enabling $openrepo ..."; ssu enablerepo $openrepo; done #Si le xargs de GNU n'est plus present
echo
ssu repos
