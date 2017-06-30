#!/usr/bin/env python
#coding: latin1
from os import chdir, walk, listdir
import re
from os.path import isfile, join, getsize
from argparse import ArgumentParser
from sys import stderr
from datetime import datetime
#from pdb import set_trace

def initArgs() :
	parser = ArgumentParser(description='Find bigger files.')
	parser.add_argument( "minimumSizeMB", nargs='?', type=float, help = "minum file size in MBytes, default is 10 MBytes / -.", default = 10.0 )
	parser.add_argument( "fileList", nargs='*', help = "filename list to check, default is *.", default = '*' )
	parser.add_argument( "-nr","--no-recursion", help="do NOT browse subdirectories recursively", action='store_true', default = False )
	parser.add_argument( "-d", "--dir", help="list files starting from dir, default is '.'.", default="." )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()
	# try :    args = parser.parse_args()
	# except :
		# print >> stderr,  "\n" + parser.format_help()
		# exit( -1 )

	print >> stderr, "=> Searching for files bigger than: " + str(args.minimumSizeMB) + " MBytes ...\n"

def main() :
	oneMegaBybe = 1048576.0
	initArgs()
	startTime = datetime.now()
	nbFiles=0
	print >> stderr, "=> The script " + scriptBaseName + " started at : " + str(startTime) + ".\n"
	if not args.no_recursion :
		chdir( args.dir )
		regExp = "|".join( args.fileList ).replace('?', '.').replace('*', '.*').replace('|', '$|')
		regExp += "$"
		pattern = re.compile(regExp, re.I)
		bigList = []
		for root, dirs, files in walk('.') :
#			print >> stderr, "=> Scanning subdirectory <" + args.dir+root[1:] + ">..."
			matchingFileList = [ join(root, file) for file in files if isfile(join(root, file)) and pattern.search( file ) and getsize(join(root, file))/oneMegaBybe >= args.minimumSizeMB ]
			matchingFileList = sorted(matchingFileList, key=getsize, reverse = True)
			if len( matchingFileList ) : bigList += matchingFileList

		bigList = sorted(bigList, key=getsize, reverse = True)
		for currentFile in bigList :
			sizeMB = getsize( currentFile )/oneMegaBybe
			print "=> The file < " + currentFile + " > is " + str(sizeMB) + " MBytes."
			nbFiles+=1
	else :
		chdir( args.dir )
		regExp = "|".join( args.fileList ).replace('?', '.').replace('*', '.*').replace('|', '$|')
		regExp += "$"
		pattern = re.compile(regExp, re.I)
		matchingFileList = [ name for name in listdir( '.' ) if isfile(name) and pattern.search( name ) and getsize( name )/oneMegaBybe >= args.minimumSizeMB ]
		matchingFileList = sorted(matchingFileList, key=getsize, reverse = True)
		for currentFile in matchingFileList :
			sizeMB = getsize( currentFile )/oneMegaBybe
			print "=> The file < " + currentFile + " > is " + str(sizeMB) + " MBytes."
			nbFiles+=1

	print >> stderr, "\n=> It took : " + str(datetime.now()-startTime) + " for the script <" + scriptBaseName + "> to find < " + str(nbFiles) +  " > files bigger than " +str(args.minimumSizeMB)+ " MBytes."

main()
