#!/usr/bin/env python
#coding: latin1

import os
from os.path import isfile, basename, splitext
from argparse import ArgumentParser
from sys import stderr, exit

def initArgs() :
	parser = ArgumentParser(description='locate a command')
	parser.add_argument( "scriptList", nargs='+', help = "scripts list to find in PATH.", default = '*' )

	global args, scriptBaseName
	scriptBaseName = parser.prog
	args = parser.parse_args()

#	try :    args = parser.parse_args()
#	except :
#		print >> stderr,  "\n" + parser.format_help()
#		exit( -1 )

def main() :
	initArgs()
	nbFiles=0
	extensionList = [ ".exe", ".com", ".dll", ".cpl", ".cmd", ".bat", ".msc", ".pl", ".py", ".rb", ".vbs" ]
	if os.name == "posix" : extensionList += [ ".sh", ".ksh", ".bash" ]
	PATH = os.environ["PATH"]

	for script in args.scriptList :
		found = False
		for currentExtension in extensionList :
			for currentPath in PATH.split( os.pathsep ) :
				if isfile( currentPath + os.sep + splitext(basename(script))[0] + currentExtension ) :
					found = True
					print currentPath + os.sep + splitext(basename(script))[0] + currentExtension
					
		if not found : print >> stderr, scriptBaseName + ": no " + script + " in (" + PATH + ")"

main()
