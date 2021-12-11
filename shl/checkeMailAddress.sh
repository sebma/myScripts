#!/usr/bin/env bash

if [ $# -lt 1 ]
then
	echo "Usage: $0 <email_address>" >&2
	exit 1
fi

domain=$(echo $1 | cut -d@ -f2)
echo "domain=$domain"
mailer=$(dig -t mx $domain +short | head -1 | cut -d" " -f2)
if [ -z $mailer ]
then
	echo "No MX or A records for $domain" >&2
	exit 2
fi

echo "mailer=$mailer"

echo -e "helo client\nmail from:<toto@tutu.fr>\nrcpt to:<$1>" | nc $mailer 25
