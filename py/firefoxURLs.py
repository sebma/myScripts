#!/usr/bin/env python2

import json
import platform, os
from sys import argv

firefoxProfileName = argv[1]
HOME = os.environ["HOME"]
if   platform.system() == 'Darwin' :
	firefoxProfilesDIR = HOME + "/Library/Application Support/Firefox/Profiles"
elif platform.system() == 'Linux' :
	firefoxProfilesDIR = HOME + "/.mozilla/firefox"

f = open( firefoxProfilesDIR + os.sep + firefoxProfileName + os.sep + "sessionstore-backups" + os.sep + "recovery.js", "r")
jdata = json.loads(f.read())
f.close()
for win in jdata.get("windows"):
	for tab in win.get("tabs"):
		i = tab.get("index") - 1
		print tab.get("entries")[i].get("url")
