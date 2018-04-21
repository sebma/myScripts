#!/usr/bin/env python
#coding: latin1

import os
from os.path import basename, dirname, isfile
from os import chdir, getcwd, listdir, read
from argparse import ArgumentParser
from sys import stderr, exit, argv
from hashlib import sha1, sha224, sha256, sha384, sha512
from datetime import datetime
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "fileList", nargs='*', help = "filename list to check, default is stdin / -.", default = "-" )
	parser.add_argument( "-a","--algorithm", type=int, help="1 (default), 224, 256, 384, 512", default = 1 )
	parser.add_argument( "-b","--binary", help="read files in binary mode (default on DOS/Windows)", action='store_true', default = True )
	parser.add_argument( "-t","--text", help="read files in text mode (default on Unix/Linux)", action='store_true', default = False )
	parser.add_argument( "-c","--check", help="check SHA sums against given list" )

	global args
	try :    args = parser.parse_args()
	except :
		print >> stderr,  "\n" + parser.format_help()
		exit( -1 )
	
	if args.text : args.binary = False
	if args.binary : args.text = False

def calcSHASum(filename, method) :
	if   method == 1   : h = sha1()
	elif method == 224 : h = sha224()
	elif method == 256 : h = sha256()
	elif method == 384 : h = sha384()
	elif method == 512 : h = sha512()
	else : print >> stderr, "=> ERROR: Unknown method."; exit(2)

	#On lit le fichier par blocks de 4ko qu'on concatene a l'objet m de type 'hashlib'
	if filename != "-" :
		if   args.binary or not args.text : fileHandle = open(filename, "rb")
		elif args.text or not args.binary : fileHandle = open(filename, "rt")
		while True:
			data = fileHandle.read(4*1024*1024)
			if not data: break
			h.update(data)
		fileHandle.close()
	else :
		while True:
			data = read(0, 4*1024)
			if not data: break
			h.update(data)

	hashed = h.hexdigest()
	return hashed

def verifyChecksums(checksumFile) :
	textFile = open(checksumFile, "rt")

	line = " "
	nbFailedChecksums = 0
	nbChecksums = 0
	while line != "" :
		line = textFile.readline()
		if   line == ""   : break #readline renvoie une chaine vide si la fin de fichier a ete rencontree
		elif line == "\n" : continue

		line = line.strip()
		if line != "" and line[0] != "#" :
			expectedChecksum = line.split()[0]
			currentFileName = line.split()[1]
			if currentFileName[0] == '*' : currentFileName = currentFileName[1:]

			nbChars = len( expectedChecksum )
			if nbChars == 40 : method = 1
			else : method = nbChars*4

			effectiveChecksum = calcSHASum(currentFileName,method)
			if effectiveChecksum == expectedChecksum :
				print currentFileName + ": OK"
			else :
				print >>stderr, currentFileName + ": FAILED"
				nbFailedChecksums+=1
			nbChecksums+=1

	if nbFailedChecksums > 0 : print >> stderr, "sha" + str(method) + "sum: WARNING:",nbFailedChecksums,"of",nbChecksums, "computed checksums did NOT match"

	return nbFailedChecksums

def main() :
	initArgs()
	startTime = datetime.now()

	if args.check : verifyChecksums(args.check)
	else :
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

				nbFiles = len( matchingFileList )
				if nbFiles != 0 :
					matchingFileList = sorted( matchingFileList )
					for baseFileName in matchingFileList :
						hash = calcSHASum( baseFileName , args.algorithm )
						print hash + " *" + dirName + os.sep + baseFileName
				else :
					print >> stderr, "=> ERROR: No corresponding file was found."
					exit(1)
			else :
				hash = calcSHASum( currentFile , args.algorithm )
				print hash + " *" + currentFile

			if os.sep in currentFile : chdir( previousDir )

	print >> stderr, "=> The script", basename(__file__) + " took " + str(datetime.now()-startTime) + " to process < " + str( nbFiles ) + " > files."

main()
