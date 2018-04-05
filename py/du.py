#!/usr/bin/env python
#coding: latin1
import os
from os import chdir, getcwd, walk, listdir
import re
from os.path import basename, dirname, isdir, isfile, join, getsize
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser
from sys import stderr, exit, argv
from datetime import datetime
import decimal
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	parser = ArgumentParser(description = 'Summarize disk usage of each FILE, recursively for directories.')
	parser.add_argument( "dirList", nargs='*', help = "dirnames to check, default is *.", default = '.' )
	parser.add_argument( "-s","--summarize", help="display only a total for each argument", action='store_true', default = False )
	parser.add_argument( "-H","--human-readable", help="print sizes in human readable format (e.g., 1K 234M 2G)", action='store_true', default = False )
	parser.add_argument( "-k","--kiloByte", help="print sizes in kilobytes", action='store_true', default = True )
	parser.add_argument( "-m","--megaByte", help="print sizes in megabytes", action='store_true', default = False )
	parser.add_argument( "-b","--Byte", help="print sizes in bytes", action='store_true', default = False )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()
	# try :    args = parser.parse_args()
	# except :
		# print >> stderr,  "\n" + parser.format_help()
		# exit( -1 )

	if args.human_readable :
		args.kiloByte = False
		args.megaByte = False
	elif args.megaByte :
		args.Byte = False
		args.kiloByte = False
	elif args.Byte :
		args.kiloByte = False
		args.megaByte = False
	elif args.kiloByte :
		args.Byte = False
		args.megaByte = False

def getDirSize( dir ) :
	previousDir = getcwd()
	chdir(dir)
	size = 0.0
	for file in listdir( '.' ) :
		if pattern.search( file ) and isfile(file) : 
			size += getsize( file )

	chdir( previousDir )
	return size

def printSize( elem, size ) :
	unit = ''
	if   args.human_readable :
		if size > 1024 : size/=1024 ; unit ='K'
		if size > 1024 : size/=1024 ; unit ='M'
		if size > 1024 : size/=1024 ; unit ='G'
		print str(round(size,1)) + unit + '\t' + elem
	elif args.kiloByte :
		size /= 1024.0
		print str(round(size,1)) + unit + '\t' + elem
	elif args.megaByte :
		size /= 1024.0*1024
		print str(round(size,1)) + unit + '\t' + elem
	elif args.Byte : 
		print str(size) + unit + '\t' + elem

def main() :
	initArgs()
	startTime = datetime.now()
	regExp = '|'.join( '*' ).replace('?', '.').replace('*', '.*').replace('|', '$|')
	regExp += '$'
	global pattern
	pattern = re.compile(regExp, re.I)
	previousDir = getcwd()
	for currentGlobbingPattern in args.dirList :
		matchingFileList = glob( currentGlobbingPattern )
		for elem in matchingFileList :
			if isdir( elem ) :
				currentDir = elem
				chdir( currentDir )
				parentDirSize = 0.0
				for dir, subDirs, files in walk( '.', topdown=False ) :
					subDirSize = 0.0
					for file in files :
						currentFile = join(dir, file)
						if pattern.search( file ) and isfile(currentFile) :
							subDirSize += getsize(currentFile)

					# subDirSize = getDirSize( dir )
					parentDirSize += subDirSize
					if len(subDirs) == 0 :
						if not args.summarize : printSize( dir, subDirSize )
					else :
						if not args.summarize : printSize( dir, parentDirSize )

				if args.summarize : printSize( currentDir, parentDirSize )
				chdir( previousDir )
			elif isfile( elem ) :
				printSize( elem, getsize( elem ) )

		if len(matchingFileList) == 0 :
				print >> stderr, scriptBaseName + ": cannot access `" + currentGlobbingPattern + "': No such file or directory"

	print >> stderr, "\n=> It took : " + str(datetime.now()-startTime) + " for the script <" + scriptBaseName + "> to run.\n"

main()
