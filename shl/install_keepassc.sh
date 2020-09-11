#!/bin/bash

if [[ -z `command -v keepassc` ]]; then
  sudo apt-get build-dep python-crypto
  githubRepos="dlitz/pycrypto raymontag/kppy raymontag/keepassc"
  for githubRepo in $githubRepos; do
    repoName=`echo ${githubRepo} | awk -F/ '{print $2}'`
    repoLocation=/usr/local/src/${repoName}
    git clone https://github.com/${githubRepo} $repoName
    cd $repoName
    python3 setup.py build
    sudo python3 setup.py install
	cd -
  done
fi
