#!/usr/bin/env python
#coding: latin1

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from IniFileParser import ParameterFileParser

class InitArgs :
	def __init__(self) :
		parser = ArgumentParser( description = 'Get INI file parameter/section.' , formatter_class=ArgumentDefaultsHelpFormatter )
		parser.add_argument("iniFileName", help="filename to edit")
		parser.add_argument("-s", "--section", help="section(s) in the ini file", required=True)
		parser.add_argument("-p", "--parameter", help="select the parameter in the ini file")

		args = parser.parse_args()

		self.iniFileName = args.iniFileName
		self.section = args.section
		self.parameter = args.parameter
		self.scriptBaseName = parser.prog

class main :
	args = InitArgs()
	p1 = ParameterFileParser(args.iniFileName)
	if args.parameter :
		value = p1.getAttribute( args.section, args.parameter )
		if value : print value
	else :
		s = p1.getSection( args.section )
		if s :
			print args.section
			s.toConsole()
