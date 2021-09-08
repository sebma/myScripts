#!/usr/bin/env bash

pdf2jpg () {
	pageRage=all
	pdfFileName=unset
	imageFileNamePrefix=unset
	if [ $# = 0 ] || [ "$1" = -h ];then
		echo "=> INFO: Usage : $FUNCNAME [pageRage] pdfFileName [imageFileNamePrefix]"
		return 1
	fi

	if [ $# = 1 ];then
		pdfFileName="$1"
		imageFileNamePrefix="${pdfFileName%.*}-%02d"
	elif [ $# = 2 ];then
		pageRage="$1"
		pdfFileName="$2"
		imageFileNamePrefix="${pdfFileName%.*}-%02d"
	elif [ $# = 2 ];then
		pageRage="$1"
		pdfFileName="$2"
		imageFileNamePrefix="$3"
	fi

	if [ $pageRage = all ];then
		convert "$pdfFileName" "${imageFileNamePrefix}.jpg"
	else
		convert "${pdfFileName}[$pageRage]" "${imageFileNamePrefix}.jpg"
	fi

	return
}
pdf2jpg "$@"
