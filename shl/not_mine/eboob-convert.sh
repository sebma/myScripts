#!/bin/bash

commande="ebook-convert"
which "$commande" > /dev/null 2>&1 
if [ $? -ne 0 ]; then
	echo -e "Unable to find \e[31m$commande\e[0m. Please install Calibre first."
	exit 1
fi

GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
declare -A fmt_ary
fmt_ary["epub"]="Standard ebook format"
fmt_ary["mobi"]="Mobipocket format"
fmt_ary["azw3"]="Amazon Kindle format"
fmt_ary["docx"]="Microsoft Word format"
fmt_ary["fb2"]="Fiction book format"
fmt_ary["htmlz"]="HTML zip ebook format"
fmt_ary["lit"]="Microsoft's native format"
fmt_ary["lrf"]="Sony's proprietary format"
fmt_ary["pdb"]="Palm Doc ebook format"
fmt_ary["pdf"]="Portable document format"
fmt_ary["pmlz"]="Palm markup language zip format"
fmt_ary["rb"]="Rocket ebook format"
fmt_ary["rtf"]="Rich text format"
fmt_ary["snb"]="Shanda Bambook format"
fmt_ary["tcr"]="EPOC ebook file format"
fmt_ary["txt"]="Simple text format"
fmt_ary["txtz"]="TXT zip ebook format"
fmt_ary["zip"]="Archive file format"

# displaying all available formats aligned, and asks...
for f in "${!fmt_ary[@]}"; do
	# bash aligns even with non printed chars... need a trick around
	printf "%$((7+${#GREEN}+${#NORMAL}))s %s\n" "[$GREEN${f^^}$NORMAL]" "${fmt_ary[$f]}"
done | sort
# line with x times the same char '-'. printf pads it with spaces, tr sets it to the desired symbol
printf '%30s\n' | tr ' ' '-'
echo -n "Enter output file format and press [ENTER]: "
read format
# force to lowercase from now on
format="${format,,}"

# checking if format available or not, terminates otherwise
if [ -z "${fmt_ary[$format]}" ]; then
	echo -e "Format \e[31m[$format]\e[0m unavailable or unknown"
	exit 2
fi

# multithreading function
function wait_jobs_down() {
	local nr_jobs
	if [[ -z $1 ]]; then
		nr_jobs=$(nproc)
	else
		nr_jobs=$1
	fi

	while [[ $(jobs -p | wc -l) -ge $nr_jobs ]]; do
		sleep 0.1
	done
}

# conversion of all files in current directory
for file in *.{epub,azw3,azw,prc,mobi,txt,doc,docx,fb2,txtz,htmlz}; do
	ebook-convert "$file" "${file%.*}.$format" & 
	wait_jobs_down
done
