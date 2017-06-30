#Association du protocole apt:, ssh: avec les applications adequoites
echo "=> Association du protocole apt:, ssh: avec les applications adequoites ..."
xdg-mime default apturl.desktop x-scheme-handler/apt
xdg-mime default putty.desktop x-scheme-handler/ssh

for browser in midori qupzilla firefox chromim-browser konqueror
do
	which $browser >/dev/null 2>&1 && defaultBrowser=$browser && break
done

echo "=> defaultBrowser = $defaultBrowser"
echo "=> Association des protocoles http et https avec $defaultBrowser ..."
xdg-mime default $defaultBrowser.desktop x-scheme-handler/http x-scheme-handler/https
echo "=> Fait."
