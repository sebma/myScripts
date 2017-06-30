#!/usr/bin/env python
#coding: latin1

import os
from os.path import basename, dirname, isfile
from os import chdir, getcwd, listdir, read
from argparse import ArgumentParser
from sys import stderr, exit, argv
from datetime import datetime

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "fileList", nargs='*', help = "filename list to check, default is stdin / -.", default = "*" )

	global args
	try :    args = parser.parse_args()
	except :
		print >> stderr,  "\n" + parser.format_help()
		exit( -1 )

def main() :
	initArgs()
	startTime = datetime.now()

	for currentFile in args.fileList :
		if os.sep in currentFile :
			previousDir = getcwd()
			dirName = dirname( currentFile )
			chdir( dirName )
			pattern = basename( currentFile )
		else :
			dirName = '.'
			pattern = currentFile

		if pattern[0] == '*' :
			patternLength = len( pattern )
			if patternLength > 1 :
				if pattern[2] == '*' :
					if patternLength == 3 :
						matchingFileList = listdir( '.' )
					else :
						matchingFileList = [ name for name in listdir( '.' ) if isfile(name) and name.endswith( pattern[3:] ) ]
				else :
					matchingFileList = [ name for name in listdir( '.' ) if isfile(name) and name.endswith( pattern[1:] ) ]
			else :
				matchingFileList = listdir( '.' )

			nbFiles = len( matchingFileList )
			if nbFiles != 0 :
				matchingFileList = sorted( matchingFileList )
				for baseFileName in matchingFileList :
					print dirName + os.sep + baseFileName
			else :
				print >> stderr, "=> ERROR: No corresponding file was found."
				exit(1)
		else :
			print currentFile

		if os.sep in currentFile : chdir( previousDir )

	print >> stderr, "=> The script", basename(__file__) + " took " + str(datetime.now()-startTime) + " to process < " + str( nbFiles ) + " > files."

main()
