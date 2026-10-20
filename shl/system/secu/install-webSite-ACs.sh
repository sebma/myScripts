#!/usr/bin/env bash

webSite=$1
openssl s_client -connect $webSite:443 -showcerts </dev/null 2>/dev/null | awk -v webSite=$webSite '
/-----BEGIN CERTIFICATE-----/ { n++; out=webSite "-" n ".crt" }
out { print > out }
/-----END CERTIFICATE-----/ { close(out); out="" }
'
