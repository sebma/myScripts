#!/usr/bin/env python
#coding: latin1
import os, sys
from os import chdir, walk, remove, fdopen
import re
import string
from os.path import basename, dirname, isdir, isfile, join, exists
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser
from sys import stderr, stdout, exit, argv
from datetime import datetime
import shutil
from shutil import copy2
from tempfile import mkstemp
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	global args, scriptBaseName

	parser = ArgumentParser(description = 'stream editor for filtering and transforming text')
	parser.add_argument( "-i","--inplace", help="edit files in place (makes backup if extension supplied)" )
	parser.add_argument( "-v","--verbose", default = False, action='store_true', help="show what is being done" )
	parser.add_argument( "sedRegExp", help = "filename list to check" )
	parser.add_argument( "fileList", nargs='*', help = "filename list to check", default = '-' )

	args = parser.parse_args()
	scriptBaseName = parser.prog

	if args.sedRegExp[0] == "'" and args.sedRegExp[-1] == "'" : args.sedRegExp = args.sedRegExp[1:-1]
	if args.verbose : print >> stderr, "=> Running the command : " + " ".join(argv) + "\n"

def firstMatch( pattern, file ) :
	if file == '-' : textfile = sys.stdin
	else :			textfile = open(file)
	for line in textfile :
		if pattern.search( line ) :
			textfile.close()
			return True

	if file != '-' : textfile.close()

	return False

def dos2unix(fmask):
	for fname in glob(fmask) :
		with open(fname,"rb") as fp : text = fp.read()
		with open(fname,"wb") as fp : fp.write(text.replace('\r\n','\n'))

def unix2dos(fmask):
	for fname in glob(fmask) :
		with open(fname,"rb") as fp : text = fp.read()
		if string.find(text,'\r') < 0 :
			with open(fname,"wb") as fp : fp.write(text.replace('\n','\r\n'))

def isUnixFile(fileName) :
	with open(fileName,"rb") as fileHandle :
		firstLine = fileHandle.readline()
	return "\r\n" not in firstLine

def splitPattern( sedRegExp ) :
	if sedRegExp[0]  == 's' : separator = sedRegExp[1]
	if sedRegExp[-1] == 'g' : count = 0

	list = sedRegExp.split(separator)
	regExp = list[1]
	replaceExp = list[2]

	if args.verbose :
		print >> stderr, "=> regExp = " + regExp
		print >> stderr, "=> replaceExp = " + replaceExp + "\n"

	pattern = re.compile( regExp )
	if len(list) == 4 :
		if 'g' in list[3] : count = 0
		else : count = 1
		if 'i' or 'I' in list[3] : pattern = re.compile( regExp, re.I )

	return pattern, replaceExp, count

def sed( pattern, replaceExp, count, file ) :
	if args.inplace is None or file == '-' :
		if file == '-' : infile = sys.stdin
		else :			infile = open(file)

		if args.verbose :
			nbMatch = 0
			for line in infile :
				if pattern.search(line) : nbMatch +=1
				print pattern.sub( replaceExp, line, count ),
			print >> stderr, "==> Found pattern in " + str(nbMatch) + " line(s) in < stdin > .\n"
		else :
			for line in infile :
				print pattern.sub( replaceExp, line, count ),

		if file != '-' : infile.close()
	else :
		if args.inplace != "" :
			fileBackup = file + args.inplace
		else :
			tempFileHandle, tempFileName = mkstemp()
			os.close(tempFileHandle)
			fileBackup = tempFileName

		try :
			if args.verbose : print >> stderr, "==> Backing up file < " + file + " > to < " + fileBackup + " >."
			copy2( file, fileBackup )
		except shutil.Error as why :
			print >> stderr, "\n==> ERROR: %s." % why
			return 1
		else :
			if args.verbose : print >> stderr, "==> Done."

		with open( fileBackup ) as infile :
			with open( file, "w" ) as outfile :
				if args.verbose :
					nbMatch = 0
					for line in infile :
						if pattern.search(line) : nbMatch += 1
						print >> outfile, pattern.sub( replaceExp, line, count ),
					print >> stderr, "==> Replaced pattern in " + str(nbMatch) + " line(s) in the file < " + file + " > .\n"
				else :
					for line in infile :
						print >> outfile, pattern.sub( replaceExp, line, count ),

		if os.name == "nt" and isUnixFile( fileBackup ) : dos2unix(file)
		if os.name == "posix" and not isUnixFile( fileBackup ) : unix2dos(file)

		if args.inplace == "" : remove( fileBackup )

def main() :
	initArgs()
	startTime = datetime.now()
	retCode = 0
	pattern, replaceExp, count = splitPattern( args.sedRegExp )
	if args.sedRegExp[0] == 's' :
		if args.fileList == '-' :
			if firstMatch( pattern, '-' ) : sed( pattern, replaceExp, count, '-' )
			else : print >> stderr, "==> The pattern was not found in < stdin >."
		else :
			for currentGlobbingPattern in args.fileList :
				if isdir( currentGlobbingPattern ) : currentGlobbingPattern += os.sep + '*'
				elif '*' not in currentGlobbingPattern :
					if not exists( currentGlobbingPattern ) :
						print >> stderr, "=> ERROR: The file < " + currentGlobbingPattern + " > does not exists."
						retCode = 2
				for currentFile in glob( currentGlobbingPattern ) :
					if isfile(currentFile) :
						if args.verbose : print >> stderr, "=> Treating file < " + currentFile + " > ..."
						if firstMatch( pattern, currentFile ) :
							retCode = sed( pattern, replaceExp, count, currentFile )
						elif args.verbose :
							print >> stderr, "==> The pattern was not found in the file < " + currentFile + " >."

	exit( retCode )

main()
