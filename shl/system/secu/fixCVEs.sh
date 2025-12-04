#!/usr/bin/env bash

function fixCVEs {
	set -o errexit
	set -o nounset
	cveListRegExp=${@#CVE-}
	cveListRegExp="CVE-(${cveListRegExp// /|})"

	#sudo apt install -V $(debsecan --suite $(cut -d/ -f2 /etc/debian_version) --only-fixed | egrep "$cveListRegExp" | cut -d" " -f2 | sort -u)
}

fixCVEs "$@"
