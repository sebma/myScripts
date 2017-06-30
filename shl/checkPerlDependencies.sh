#!/bin/ksh

perlScript=$1
awk '/use .*;/{print$2}' $perlScript | sed "s/;$//" | while read modul
do
  perl -l -M$modul -e "print \"The version of the $modul Perl module is \$$modul::VERSION\""
done
