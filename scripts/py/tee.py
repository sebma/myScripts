#!/usr/bin/env python
#coding: latin1

from os.path import isfile
from argparse import ArgumentParser
from sys import stdin, stdout, exit

def initArgs() :
	parser = ArgumentParser(description = 'Copy standard input to each FILE, and also to standard output.')
	parser.add_argument( "-a","--append", default = False, action='store_true', help="append to the given FILEs, do not overwrite" )
	parser.add_argument( "fileList", nargs='*', help = "Search for PATTERN in each FILE or standard input" )

	global args, scriptBaseName
	args = parser.parse_args()
	scriptBaseName = parser.prog

def main() :
	initArgs()
	retCode = 0
	mode = "w"
	wholeStdin = stdin.read()

	stdout.write( wholeStdin )
	if args.fileList :
		if args.append : mode = "a"
		for currentFile in args.fileList:
			if currentFile == '-' :
				 stdout.write( wholeStdin )
			else :
				with open( currentFile, mode ) as outfile :
					outfile.write(wholeStdin)

	exit( retCode )

main()
