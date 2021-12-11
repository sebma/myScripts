#!/usr/bin/env bash
tocFile=$1
pdfFile=$2
test $tocFile && test $pdfFile && pdftk $pdfFile update_info_utf8 $tocFile output $pdfFile.new verbose && mv -v $pdfFile.new $pdfFile
