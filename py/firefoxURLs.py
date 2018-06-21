#!/usr/bin/env python3

from __future__ import print_function
import json, lz4.block
import platform, os
from os.path import exists
from sys import argv

firefoxProfileName = argv[1]
HOME = os.environ["HOME"]
if   platform.system() == 'Darwin' :
	firefoxProfilesDIR = HOME + "/Library/Application Support/Firefox/Profiles"
elif platform.system() == 'Linux' :
	firefoxProfilesDIR = HOME + "/.mozilla/firefox"
elif platform.system() == 'Windows' :
	APPDATA = os.environ["APPDATA"]
	firefoxProfilesDIR = APPDATA + os.sep + "Mozilla" + os.sep +"Firefox" + os.sep + "Profiles"

chosenFirefoxProfileDIR = firefoxProfilesDIR + os.sep + firefoxProfileName
sessionstoreBackupsDIR  = chosenFirefoxProfileDIR + os.sep + "sessionstore-backups"

# Thanks to : https://unix.stackexchange.com/questions/385023/firefox-reading-out-urls-of-opened-tabs-from-the-command-line/389360#389360

if exists( sessionstoreBackupsDIR + os.sep + "recovery.js" ) :
	firefoxOpenedTabsFile = sessionstoreBackupsDIR + os.sep + "recovery.js"
else :
	firefoxOpenedTabsFile = sessionstoreBackupsDIR + os.sep + "recovery.jsonlz4"

with open( firefoxOpenedTabsFile, "r" ) as f :
	if "jsonlz4" in firefoxOpenedTabsFile :
		jdata = json.loads(lz4.block.decompress(f.read()).decode("utf-8"))
	else :
		jdata = json.loads(f.read())

for win in jdata.get("windows"):
	for tab in win.get("tabs"):
		i = tab.get("index") - 1
		print( tab.get("entries")[i].get("url") )
