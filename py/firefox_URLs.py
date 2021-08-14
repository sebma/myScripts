#!/usr/bin/env python2

from __future__ import print_function
import json
import platform, os
from os.path import exists, basename
from sys import argv, stderr

try :
	from ipdb import set_trace
except ImportError as why :
	print( why )
	from pdb import set_trace

scriptBaseName = basename( argv[0] )
HOME = os.environ["HOME"]
if   platform.system() == 'Darwin' :
	if 'firefox' in scriptBaseName.lower() :
		firefoxProfilesDIR = HOME + "/Library/Application Support/Firefox/Profiles"
	elif 'palemoon' in scriptBaseName.lower() :
		firefoxProfilesDIR = HOME + "/Library/Application Support/Pale Moon/Profiles"
elif platform.system() == 'Linux' :
	if 'firefox-esr' in scriptBaseName.lower() :
		firefoxProfilesDIR = HOME + "/.mozilla/firefox-esr"
	elif 'palemoon' in scriptBaseName.lower() :
		firefoxProfilesDIR = HOME + "/.moonchild productions/pale moon"
	elif 'firefox' in scriptBaseName.lower() :
		firefoxProfilesDIR = HOME + "/.mozilla/firefox"
elif platform.system() == 'Windows' :
	APPDATA = os.environ["APPDATA"]
	firefoxProfilesDIR = APPDATA + os.sep + "Mozilla" + os.sep +"Firefox" + os.sep + "Profiles" # A COMPLETER EN FONCTION DU "scriptBaseName"

argc = len(argv)
if argc == 1 :
	filesInFirefoxProfilesDIR = os.listdir( firefoxProfilesDIR )
	filesInFirefoxProfilesDIR.sort()
	for item in "profiles.ini","Pending Pings","Crash Reports" :
		if item in filesInFirefoxProfilesDIR : filesInFirefoxProfilesDIR.remove( item )
	print( "\n".join( filesInFirefoxProfilesDIR ), file = stderr )
	exit(0)
else :
	firefoxProfileName = argv[1]

chosenFirefoxProfileDIR = firefoxProfilesDIR + os.sep + firefoxProfileName
sessionstoreBackupsDIR  = chosenFirefoxProfileDIR + os.sep + "sessionstore-backups"

if exists( chosenFirefoxProfileDIR + os.sep + "sessionstore.js" ) :
	firefoxOpenedTabsFile = chosenFirefoxProfileDIR + os.sep + "sessionstore.js"
elif exists( sessionstoreBackupsDIR + os.sep + "recovery.js" ) :
	firefoxOpenedTabsFile = sessionstoreBackupsDIR + os.sep + "recovery.js"
elif exists( sessionstoreBackupsDIR + os.sep + "recovery.jsonlz4" ) :
	firefoxOpenedTabsFile = sessionstoreBackupsDIR + os.sep + "recovery.jsonlz4"
else :
	print("=> ERROR : Cannot find the %s directory." % sessionstoreBackupsDIR,file=stderr)
	exit(1)

print("=> firefoxOpenedTabsFile = %s" % firefoxOpenedTabsFile,file=stderr)

openMode = 'r'
with open( firefoxOpenedTabsFile, openMode ) as f :
# Thanks to : https://unix.stackexchange.com/questions/385023/firefox-reading-out-urls-of-opened-tabs-from-the-command-line/389360#389360
	if "jsonlz4" in firefoxOpenedTabsFile :
		import lz4.block
		if f.read(8) != b"mozLz40\0": raise InvalidHeader("Invalid magic number") #Mozilla specific magic number
		jdata = json.loads(lz4.block.decompress(f.read()))
	else :
		try :
			jdata = json.loads(f.read())
		except TypeError as why :
			print( why, file = stderr )
			jdata = json.loads( f.read().decode('utf-8') )

for win in jdata.get("windows"):
	for tab in win.get("tabs"):
		i = tab.get("index") - 1
		print( tab.get("entries")[i].get("url") )
