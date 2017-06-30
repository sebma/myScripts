#!/usr/bin/env python
#coding: latin1
import os, sys
from os import chdir, walk
import re
from os.path import basename, dirname, isdir, isfile, join, exists
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser
from sys import stderr, exit, argv
from datetime import datetime
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	global args, scriptBaseName

	parser = ArgumentParser(description = 'Search for PATTERN in each FILE or standard input.')
	parser.add_argument( "-i","--ignore-case", help="ignore case distinctions", action='store_true', default = False )
	parser.add_argument( "-n","--line-number", help="print line number with output lines", action='store_true', default = False )
	parser.add_argument( "-l","--files-with-matches", help="only print FILE names containing matches", action='store_true', default = False )
	parser.add_argument( "--no-filename", help="suppress the prefixing filename on output", action='store_true', default = False )
	parser.add_argument( "-q","--quiet", help="suppress all normal output", action='store_true', default = False )
	parser.add_argument( "-r","--recursive", help="scan subdirectories recursively", action='store_true', default = False )
	parser.add_argument( "-c","--count", help="only print a count of matching lines per FILE", action='store_true', default = False )

	parser.add_argument( "regExp", help = "filename list to check, default is '.'", default = '.' )
	parser.add_argument( "fileList", nargs='*', help = "Search for PATTERN in each FILE or standard input", default = '-' )
	parser.add_argument( "dir", nargs='?', help = "directory to search", default = '.' )
	parser.add_argument( "-I", "--include", nargs='?', help="filenames that match PATTERN will be examined", default = '*'  )

	args = parser.parse_args()
	scriptBaseName = parser.prog

	if args.recursive and len( args.fileList ) != 0 and args.fileList != "*" :
		parser.print_usage(stderr)
		exit( -2 )

	if args.regExp[0] == "'" and args.regExp[-1] == "'" : args.regExp = args.regExp[1:-1]

def grep( regExp, file ) :
	if args.ignore_case :
		pattern = re.compile( regExp, re.I )
	else :
		pattern = re.compile( regExp )

	nbMatch = 0
	lineno = 0
	if file == '-' : textfile = sys.stdin
	else :			textfile = open(file)

	for line in textfile :
		lineno += 1
		if pattern.search( line ) :
			nbMatch += 1
			if args.files_with_matches is False and args.quiet is False :
				if not args.count :
					if args.no_filename is False : print file + ":",
					if args.line_number : print str(lineno) + ":",
					print line,

	if args.count : print file + ":" + str(nbMatch)

	if file != '-' : textfile.close()

	if nbMatch !=0 : return True
	else : return False

def main() :
	initArgs()
	startTime = datetime.now()
	nbMatchingFiles=0
	retCode = 0

	matchingFileList = []
	if args.recursive :
		chdir( args.dir )
		if args.include == "*" : fileRegExp = "."
		else :
			fileRegExp = args.include.replace('?', '.').replace('*', '.*').replace(' ', '$|')
			fileRegExp += "$"

		namePattern = re.compile(fileRegExp, re.I)
		for root, dirs, files in walk('.') :
			for file in files :
				filePath = join(root, file)
				if namePattern.search( file ) :
					if grep( args.regExp, filePath ) :
						matchingFileList.append( filePath )
						nbMatchingFiles+=1
	else :
		if args.fileList == '-' :
			grep( args.regExp, '-' )
		else :
			for currentGlobbingPattern in args.fileList :
				if isdir( currentGlobbingPattern ) : currentGlobbingPattern += os.sep + '*'
				elif '*' not in currentGlobbingPattern :
					if not exists( currentGlobbingPattern ) :
						print >> stderr, "=> ERROR: The file < " + currentGlobbingPattern + " > does not exists."
						retCode = 2
				for currentFile in glob( currentGlobbingPattern ) :
					if isfile(currentFile) and grep( args.regExp, currentFile ) :
						matchingFileList.append( currentFile )
						nbMatchingFiles+=1

	if args.files_with_matches and args.quiet is False : print "\n".join(matchingFileList)
	if nbMatchingFiles == 0 : retCode = 1

	exit( retCode )

main()
