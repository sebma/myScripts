#!/usr/bin/env python
#coding: latin1

import argparse
from ConfigParser import RawConfigParser, SafeConfigParser
from os.path import exists, splitext
from sys import stderr
from datetime import datetime
from shutil import copy2
from string import replace

def initArgs() :
	parser = argparse.ArgumentParser()
	parser.add_argument("iniFile", help="filename to edit")
	parser.add_argument("-s", "--section", help="select the section in the ini file", required=True)
	parser.add_argument("-p", "--parameter", help="select the parameter in the ini file", required=True)
	parser.add_argument("-v", "--value", help="select the value in the ini file", required=True)

	global args
	try :   args = parser.parse_args()
	except :print parser.format_help() ; exit(1)

def unix2dos( file ) :
	contents = open(file, 'rb').read()
	open(file, 'wb').write(contents.replace('\n', '\r\n'))

def main() :
	initArgs()

	if exists( args.iniFile ) :
#		config = RawConfigParser()
		config = SafeConfigParser()
		config.optionxform = str #Permet de conserver la case dans le contenu du fichier INI
		config.read(args.iniFile)
		oldValue = ""

		if config.has_option(args.section, args.parameter) :
			oldValue = config.get(args.section, args.parameter)
			print "=> AVANT: " + args.parameter + " = " + oldValue

		if oldValue != args.value :
			config.set(args.section, args.parameter, args.value)
			try :
				iniFileBackup = splitext( args.iniFile )[0] + "_" + datetime.now().strftime('%Y.%m.%d-%Hh%Mm%Ss') + splitext( args.iniFile )[1]
				copy2(args.iniFile,iniFileBackup)
			except IOError, e :
				print >> stderr, "Unable to copy file. Retcode =" % e
				exit(2)
			else :
				print "=> Copy " + args.iniFile + " -> " + iniFileBackup + " ... Done."
				print "=> APRES: " + args.parameter + " = " + config.get(args.section, args.parameter)
				with open( args.iniFile, 'wb' ) as configfileHandle :
					config.write(configfileHandle)
				unix2dos( args.iniFile )

	else : print >> stderr, "=> ERROR: The file < " + args.iniFile + " > does not exists."

main()
