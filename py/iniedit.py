#!/usr/bin/env python
#coding: latin1

import os
import argparse
from types import StringType
from sys import exc_info
from ConfigParser import RawConfigParser, SafeConfigParser, NoSectionError, NoOptionError
from os.path import exists, splitext
from sys import stderr
from datetime import datetime
from shutil import copy2
from string import replace
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	parser = argparse.ArgumentParser(description = 'INI file updater.')
	parser.add_argument("iniFileName", help="filename to edit")
	parser.add_argument("-s", "--section", nargs = "+", help="section(s) in the ini file", required=True)
	parser.add_argument("-p", "--parameter", help="select the parameter in the ini file", required=True)
	parser.add_argument("-v", "--value", help="select the value in the ini file", required=True)
	parser.add_argument("-nb","--no-backup", help="don't backup the original file", action='store_true', default = False )
	parser.add_argument("-y", "--run", default = False, action='store_true', help="run in real mode." )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

def unix2dos( file ) :
	contents = open(file, 'rb').read()
	open(file, 'wb').write(contents.replace('\n', '\r\n'))

def iniEdit(iniFileName, section, parameter, value ) :
	if not exists( iniFileName ) :
		print >> stderr, "=> ERROR: The file < " + iniFileName + " > does not exists."
		exit(1)

	config = SafeConfigParser(allow_no_value=True)
	config.optionxform = str #Permet de conserver la case dans le contenu du fichier INI
	try :
		config.read(iniFileName)
	except :
		print >> stderr, "=> ERROR (%s) : %s." % ( exc_info()[0], exc_info()[1] )
		exit(2)

	if section[0] == '*' : section = config.sections()
	for currentSection in section :
		try :
			oldValue = config.get(currentSection, parameter)
		except NoSectionError as why :
			print >> stderr, "=> WARNING: %s." % why + ", creating it ..."
			config.add_section(currentSection)
			oldValue = ""
		except NoOptionError as why :
			oldValue = ""
		else :
			print >> stderr, "=> BEFORE: In currentSection [" + currentSection + "], " + parameter + " = <" + oldValue + ">"

		if oldValue != value :
			try :
				config.set(currentSection, parameter, value)
			except :
				print >> stderr, "=> ERROR (%s) : %s." % ( exc_info()[0], exc_info()[1] )
				exit(3)
			else :
				print >> stderr, "=> AFTER:  In currentSection [" + currentSection + "], " + parameter + " = " + config.get(currentSection, parameter)

	if args.run :
		if not args.no_backup :
			try :
				iniFileNameBackup = splitext( iniFileName )[0] + "_" + datetime.now().strftime('%Y.%m.%d-%Hh%Mm%Ss') + splitext( iniFileName )[1]
				copy2(iniFileName,iniFileNameBackup)
			except IOError as why :
				print >> stderr, "Unable to copy file. Retcode =" % why
				exit(4)
			else :
				print "=> Copy " + iniFileName + " -> " + iniFileNameBackup + " ... Done."

		# syncing the config structure to the file and converting endlines
		with open( iniFileName, 'wb' ) as configHandle : 
			config.write(configHandle)
		if os.linesep != '\n' :
			# Le ConfigParser ecrit les sauts de ligne au format UNIX donc il faut les convertir
			contents = open(iniFileName,'rb').read()
			open( iniFileName, 'wb' ).write( contents.replace('\n', os.linesep) )

def main() :
	initArgs()
	iniEdit( args.iniFileName, args.section, args.parameter, args.value )

main()
