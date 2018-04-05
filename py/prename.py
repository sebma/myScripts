#!/usr/bin/env python
#coding: latin1
import re
from os import remove
from os.path import isdir, isfile, exists
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser
from sys import stderr, stdout, exit, argv
from datetime import datetime
from shutil import move
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	parser = ArgumentParser(description = 'renames multiple files')
	parser.add_argument( "-v","--verbose", help="Verbose: print names of files successfully renamed.", action='store_true', default = False )
	parser.add_argument( "-n","--no-act", help="No Action: show what files would have been renamed.", action='store_true', default = False )
	parser.add_argument( "-f","--force", help="Force: overwrite existing files.", action='store_true', default = False )
	parser.add_argument( "sedRegExp", help = "sed expression to rename the files." )
	parser.add_argument( "fileList", nargs='*', help = "file list to rename.", default = '-' )

	global args, scriptBaseName
	scriptBaseName = parser.prog
	args = parser.parse_args()
#	try :    args = parser.parse_args()
#	except :
#		print >> stderr,  "\n" + parser.format_help()
#		exit( -1 )

	if args.sedRegExp[0] == "'" and args.sedRegExp[-1] == "'" : args.sedRegExp = args.sedRegExp[1:-1]

def firstMatchInName( sedRegExp, file ) :
	if sedRegExp[0] == 's' :
		separator = sedRegExp[1]
		list = sedRegExp.split(separator)
		regExp = list[1]
		pattern = re.compile( regExp )
		if len(list) == 4 :
			if 'i' or 'I' in list[3] : pattern = re.compile( regExp, re.I )

		if pattern.search( file ) : return True
		else : return False
	return False

def sedRenameFile( sedRegExp, file ) :
	if sedRegExp[0]  == 's' : separator = sedRegExp[1]
	if sedRegExp[-1] == 'g' : count = 0

	list = sedRegExp.split(separator)
	regExp = list[1]
	replaceExp = list[2]
	pattern = re.compile( regExp )

	if len(list) == 4 :
		if 'g' in list[3] : count = 0
		else : count = 1
		if 'i' or 'I' in list[3] : pattern = re.compile( regExp, re.I )

	newName = pattern.sub( replaceExp, file, count )
	if exists(newName ) :
		if args.force and not args.no_act :
			remove(newName)
		else :
			print >> stderr, file + " not renamed: " + newName + " already exists"
			return 0

	try :
		if not args.no_act : 
			move( file, newName )
		if args.verbose or args.no_act : print file + " renamed as " + newName
	except e :
		print >> stderr, "=> ERROR : " % e
		exit(1)

def main() :
	initArgs()
	startTime = datetime.now()
	if args.fileList != '-' :
		for currentGlobbingPattern in args.fileList :
			if isdir( currentGlobbingPattern ) : currentGlobbingPattern += os.sep + '*'
			for currentFile in glob( currentGlobbingPattern ) :
				if isfile(currentFile) :
					if firstMatchInName( args.sedRegExp, currentFile ) :
						sedRenameFile( args.sedRegExp, currentFile )

main()
