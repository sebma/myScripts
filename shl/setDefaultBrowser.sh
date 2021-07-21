#!/usr/bin/env sh

[ $# = 0 ] && browserList="google-chrome brave-browser palemoon firefox-esr firefox midori qupzilla chromium-browser konqueror" || browserList="$@"

for browser in $browserList
do
	which $browser >/dev/null 2>&1 && defaultBrowser=$browser && break
done

echo "=> Chosen defaultBrowser = $defaultBrowser"
desktopFile=$(basename $(locate /usr/share/*/$defaultBrowser.desktop) | head -1)
echo "=> Corresponding desktopFile = $desktopFile"
echo "=> Association des protocoles http et https avec $desktopFile ..."
echo "=> xdg-mime default $desktopFile x-scheme-handler/http x-scheme-handler/https ..."
xdg-mime default $desktopFile x-scheme-handler/http x-scheme-handler/https
echo "=> Verification de l'ouverture des protocoles http et https par <$defaultBrowser> ..."
xdg-mime query default x-scheme-handler/http
xdg-mime query default x-scheme-handler/https
echo "=> xdg-settings set default-web-browser $desktopFile ..."
xdg-settings set default-web-browser $desktopFile
echo "=> xdg-settings get default-web-browser ..."
xdg-settings get default-web-browser
echo "=> Fait."
