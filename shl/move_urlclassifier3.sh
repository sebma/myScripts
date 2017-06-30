#!/bin/sh

set -o nounset

pgrep -lf firefox-bin && {
  echo "=> ERROR: Firefox is still running." >&2
  exit 1
}

userID=$(id -u)
mkdir -p /tmp/$userID/.mozilla/firefox
chmod g+w /tmp/$userID/.mozilla/firefox
echo "=> BEFORE: "
ls -lh /tmp/$userID/.mozilla/firefox/*/urlclassifier3.sqlite
ls -lh --color ~/.mozilla/firefox/*/urlclassifier3.sqlite
echo

#\ls -d ~/.mozilla/firefox/*/ | awk -F/ '/[a-z0-9]+\.?[a-z0-9]+\/$/{print$(NF-1)}' | while read subdir
\ls -1 ~/.mozilla/firefox | egrep -v "profiles.ini|Crash Reports" | while read subdir
do
  echo "=> subdir = $subdir"
  mkdir -p /tmp/$userID/.mozilla/firefox/$subdir
  touch /tmp/$userID/.mozilla/firefox/$subdir/urlclassifier3.sqlite
  test -f ~/.mozilla/firefox/$subdir/urlclassifier3.sqlite && {
    test ! -h ~/.mozilla/firefox/$subdir/urlclassifier3.sqlite && {
      mv -v ~/.mozilla/firefox/$subdir/urlclassifier3.sqlite /tmp/$userID/.mozilla/firefox/$subdir/
      ln -svf /tmp/$userID/.mozilla/firefox/$subdir/urlclassifier3.sqlite ~/.mozilla/firefox/$subdir/urlclassifier3.sqlite
    }
  }
done

echo
echo "=> AFTER: "
ls -lh --color ~/.mozilla/firefox/*/urlclassifier3.sqlite
