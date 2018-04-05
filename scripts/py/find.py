#!/usr/bin/env python
#coding: latin1
import os
from os import chdir, walk
import re
from os.path import basename, isdir, join, getsize, getmtime, exists, islink, realpath
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser
from sys import stderr, exit, argv
from datetime import datetime, date
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	parser = ArgumentParser(description = 'DO NOT USE - WORK IN PROGRESS !')
	parser.add_argument( "dirList", nargs='*', default = ['.'], help = "filename list to check, default is .." )
	parser.add_argument( "-ls", default = False, help="use a long listing format.", action='store_true' )
	parser.add_argument( "-name", default = '*', help="Base of file  name that matches shell pattern pattern." )
	parser.add_argument( "-iname", help="Base of file  name that matches shell pattern pattern (case insensitive)." )
	parser.add_argument( "-maxdepth", type = int, help="Descend at most levels (a non-negative integer) levels of directories below the command line arguments." )
	parser.add_argument( "-mtime", type = int, default = 0, help="Descend at most levels (a non-negative integer) levels of directories below the command line arguments." )
	parser.add_argument( "-size", help="File uses n units of space." )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

#	try :    args = parser.parse_args()
#	except :
#		print >> stderr,  "\n" + parser.format_help()
#		exit( -1 )

	if args.size is not None :
		# print "=> args.size = " + args.size
		global unit, lastChar, sign

		if args.size[0] in [ '+', '-' ] : sign = args.size[0]
		else : sign = ""

		if args.size[-1].isdigit() :
			unit = 1.0
			lastChar = ""
			if sign :	args.size = int(args.size[1:])
			else :		args.size = int(args.size)
		else :
			lastChar = args.size[-1].upper()
			if sign :	args.size = int(args.size[1:-1])
			else :		args.size = int(args.size[:-1])

			if   lastChar == 'K' : args.size *= 1024; unit = 1024.0
			elif lastChar == 'M' : args.size *= 1024**2 ; unit = 1024.0**2
			elif lastChar == 'G' : args.size *= 1024**3 ; unit = 1024.0**3
			else : print >> stderr, "=> ERROR: Invalid size unit." ; exit(1)

def ls(file) :
	if os.name == "posix" :
		stat = os.stat(file)
		if args.ls :
			print str(stat.st_mode) + "\t" + "1" + "\t"
		else :
			print file
	else :
		if args.ls :
			if lastChar :
				print file + "\t" + str( round( getsize(file)/unit, 2 ) ) + lastChar
			else :
				print file + "\t" + str( getsize(file) )
		else :
			print file

def ageOfFile( file ) :
	return date.today() - date.fromtimestamp( getmtime( file ) )

def main() :
	initArgs()
	startTime = datetime.now()
	nbFiles = 0
	print >> stderr, "\n=> The script " + scriptBaseName + " started at : " + str(startTime) + ".\n"
	regExp = ""
	if   args.iname is not None :
		ignoreCase = True
		regExp = args.iname
	elif args.name is not None :
		ignoreCase = False
		regExp = args.name

	# regExp = '|'.join( regExp ).replace('?', '.').replace('*', '.*').replace('|', '$|')
	if regExp :
		regExp = regExp.replace(' ', '|').replace('?', '.').replace('*', '.*').replace('|', '$|')
		regExp += '$'

		if ignoreCase :
			pattern = re.compile(regExp, re.I)
		else :
			pattern = re.compile(regExp)

	for currentDir in args.dirList :
		depth = 0
		chdir( currentDir )
		for root, dirs, files in walk('.') :
			depth = root.count(os.sep)
			if args.maxdepth is not None and depth > args.maxdepth :
				continue
			for file in files :
				currentFile = join(root, file)
				# if not regExp or pattern.search( file ) and localtime(getmtime(currentFile)) > mktime(args.mtime) :

				try :
					os.stat(currentFile)
				except OSError as why :
					print >> stderr, str(why); continue

				if islink(currentFile) and not exists(realpath(currentFile)) :
					print >> stderr, "=> WARNING: The file "+currentFile+" is a dead symlink."
					continue

				if ( not regExp or pattern.search( file ) ) and ageOfFile( join(root, file) ).days >= args.mtime :
					if args.size :
						if   sign == '+' and getsize(currentFile) >= args.size :
							ls(currentFile)
							nbFiles += 1
						elif sign == '-' and getsize(currentFile) <  args.size :
							ls(currentFile)
							nbFiles += 1
						else :
							if getsize(currentFile) == args.size : ls(currentFile) ; nbFiles += 1
					else :
						ls(currentFile)
						nbFiles += 1

	print >> stderr, "\n=> It took : " + str(datetime.now()-startTime) + " for the script <" + scriptBaseName + "> to find < " + str(nbFiles) +  " > files.\n"

main()
