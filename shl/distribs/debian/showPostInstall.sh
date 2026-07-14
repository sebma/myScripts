#!/usr/bin/env bash

packageDIR=/var/lib/dpkg/info
for package
do
	less $packageDIR/$package.postinst
done
