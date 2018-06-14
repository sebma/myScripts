#!/usr/bin/env python3

from __future__ import print_function
import json, lz4
import platform, os
from os.path import exists
from sys import argv
from os.path import exists

firefoxProfileName = argv[1]
HOME = os.environ["HOME"]
if   platform.system() == 'Darwin' :
	firefoxProfilesDIR = HOME + "/Library/Application Support/Firefox/Profiles"
elif platform.system() == 'Linux' :
	firefoxProfilesDIR = HOME + "/.mozilla/firefox"

firefoxOpenedTabsFile = firefoxProfilesDIR + os.sep + firefoxProfileName + os.sep + "sessionstore-backups" + os.sep + "recovery.js"
if exists( firefoxOpenedTabsFile ) :
	f = open( firefoxOpenedTabsFile, "r" )
	jdata = json.loads(f.read())
else :
	firefoxOpenedTabsFile = firefoxProfilesDIR + os.sep + firefoxProfileName + os.sep + "sessionstore-backups" + os.sep + "recovery.jsonlz4"	
	if exists( firefoxOpenedTabsFile ) :
		f = open( firefoxOpenedTabsFile, "r" )
		jdata = json.loads(lz4.block.decompress(f.read()).decode("utf-8"))

f.close()

for win in jdata.get("windows"):
	for tab in win.get("tabs"):
		i = tab.get("index") - 1
		print( tab.get("entries")[i].get("url") )
