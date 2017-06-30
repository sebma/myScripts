#!/usr/bin/env bash

package_name=$1
ppa_user_name=$(apt-cache policy $package_name | grep -m1 500.http | awk -F/ '{print$4}')
ppa_name=$(apt-cache policy $package_name | grep -m1 500.http | awk -F/ '{print$5}')
package_version=$(apt-cache policy $package_name | awk -F"[ :]" '/Candidate:/{print$NF}')
URL=https://launchpad.net/~$ppa_user_name/+archive/ubuntu/$ppa_name/+files/${package_name}_${package_version}_source.changes
#echo "=> URL = $URL"
grep -q launchpad.net <<< "$URL" || { echo "=> ERROR: The package is not installed from <launchpad.net>" >&2 ; exit 1; }
\wget -q -O - $URL | awk '/Changes:/{f=1;next}/Checksums/{f=0}f'
