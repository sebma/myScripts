#!/usr/bin/env bash

[ $# = 0 ] && mailerList="thunderbird kmail claws-mail geary evolution mailspring" || mailerList="$@"

for mailer in $mailerList
do
	type -P $mailer >/dev/null 2>&1 && defaultMailer=$mailer && break
done

echo "=> defaultMailer = $defaultMailer"
desktopFile=$(basename $(dpkg -L $defaultMailer | grep desktop$))
echo "=> desktopFile = $desktopFile"
echo "=> Association du protocole mailto avec $desktopFile ..."
xdg-mime default $desktopFile x-scheme-handler/mailto
echo "=> Verification ..."
xdg-mime query default x-scheme-handler/mailto
#echo "=> xdg-settings set default-web-mailer $desktopFile ..."
#xdg-settings set default-web-mailer $desktopFile
#xdg-settings get default-web-mailer
echo "=> Fait."
