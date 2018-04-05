#!/usr/bin/env python
#coding: latin1

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from IniFileParser import ParameterFileParser
from sys import stderr

class InitArgs :
	def __init__(self) :
		parser = ArgumentParser( description = 'INI file updater.' , formatter_class=ArgumentDefaultsHelpFormatter )
		parser.add_argument("iniFileName", help="filename to edit")
		parser.add_argument("-s", "--section", help="section(s) in the ini file", required=True)
		parser.add_argument("-p", "--parameter", help="select the parameter in the ini file", required=True)
		parser.add_argument("-v", "--value", help="select the value in the ini file", required=True)
		parser.add_argument("-nb","--no-backup", help="don't backup the original file", action='store_true', default = False )
		parser.add_argument("-y", "--run", default = False, action='store_true', help="run in real mode." )

		args = parser.parse_args()

		self.iniFileName = args.iniFileName
		self.section = args.section
		self.parameter = args.parameter
		self.value = args.value
		self.no_backup = args.no_backup
		self.run = args.run
		self.scriptBaseName = parser.prog

class main :
	args = InitArgs()
	p1 = ParameterFileParser(args.iniFileName)

	oldValue = " ".join( p1.getAttribute( args.section, args.parameter ).split("=")[1:] ).lstrip()
	if oldValue != args.value :
		p1.setAttribute( args.section, args.parameter, args.value )
		if args.run :
			p1.toFile(args.no_backup)
		else :
			p1.toConsole()
	else :
		print >> stderr, "=> WARNING: The value you specified is that which is already set in the file, so not touching anything :\n" + oldValue
