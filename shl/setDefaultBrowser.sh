#Association du protocole apt:, ssh: avec les applications adequoites
echo "=> Association du protocole apt:, ssh: avec les applications adequoites ..."
xdg-mime default apturl.desktop x-scheme-handler/apt
xdg-mime default putty.desktop x-scheme-handler/ssh

for browser in palemoon firefox-esr firefox midori qupzilla chromim-browser konqueror
do
	which $browser >/dev/null 2>&1 && defaultBrowser=$browser && break
done

echo "=> defaultBrowser = $defaultBrowser"
desktopFile=$(basename $(dpkg -L $defaultBrowser | grep desktop))
echo "=> desktopFile = $desktopFile"
echo "=> Association des protocoles http et https avec $desktopFile ..."
xdg-mime default $desktopFile x-scheme-handler/http x-scheme-handler/https
echo "=> Verification ..."
xdg-mime query default x-scheme-handler/https
echo "=> Fait."
