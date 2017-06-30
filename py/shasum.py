#!/usr/bin/env python
#coding: latin1

import os
import string
from sys import stdout
from os.path import basename, dirname, isfile, exists, join
from os import listdir, read, chdir, walk
from glob import glob #Filename Globbing patterns
import re
from argparse import ArgumentParser
from sys import stderr, exit, argv
from hashlib import sha1, sha224, sha256, sha384, sha512
from datetime import datetime
from pdb import set_trace #To add a breakpoint for PDB debugger

def isWindowsFile(fileName) :
	with open(fileName,"rb") as fileHandle :
		firstLine = fileHandle.readline()
	return "\r\n" in firstLine

def dos2unix(fmask):
	for fname in glob(fmask) :
		with open(fname,"rb") as fp : text = fp.read()
		with open(fname,"wb") as fp : fp.write(text.replace('\r\n','\n'))

def initArgs() :
	parser = ArgumentParser(description='Print or check SHA checksums.')
	parser.add_argument( "patternList", nargs='*', help = "filename list to check, default is stdin / -.", default = "-" )
	parser.add_argument( "-a","--algorithm", type=int, help="1 (default), 224, 256, 384, 512", default = 1 )
	parser.add_argument( "-b","--binary", help="read files in binary mode (default on DOS/Windows)", action='store_true', default = True )
	parser.add_argument( "-t","--text", help="read files in text mode (default on Unix/Linux)", action='store_true', default = False )
	parser.add_argument( "-r","--recursive", help="parse subdirectories recursively", action='store_true', default = False )
	# parser.add_argument( "-p","--printHastToFile", help="print each hash to each ", action='store_true', default = False )
	parser.add_argument( "-c","--check", help="check SHA sums against given list" )
	parser.add_argument( "-d", "--dir", help="check files in dir.", default="." )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	try :    args = parser.parse_args()
	except :
		parser.print_usage(stderr)
		exit( -1 )

	if args.text : args.binary = False
	if args.binary : args.text = False
	if args.recursive and args.patternList == "-" : args.patternList = "?"

def calcSHASum(filename, method=1) :
	if   method == 1   : h = sha1()
	elif method == 224 : h = sha224()
	elif method == 256 : h = sha256()
	elif method == 384 : h = sha384()
	elif method == 512 : h = sha512()
	else : print >> stderr, "=> ERROR: Unknown method."; exit(2)

	#On lit le fichier par blocks de 4ko qu'on concatene a l'objet m de type 'hashlib'
	if filename != "-" :
		try :
			if   args.binary or not args.text : fileHandle = open(filename, "rb")
			elif args.text or not args.binary : fileHandle = open(filename, "rt")
			while True:
				data = fileHandle.read(4*1024*1024)
				if not data: break
				h.update(data)
			fileHandle.close()
		except :
			print filename + ": FAILED open or read"
			return ""
	else :
		while True:
			data = read(0, 4*1024)
			if not data: break
			h.update(data)

	hashed = h.hexdigest()
	return hashed

def verifyChecksums(checksumFile) :
	if not exists(checksumFile) :
		print >> stderr, "=> ERROR [" + scriptBaseName + "] : No such file or directory: " + checksumFile
		exit(1)
	else :
		if isWindowsFile(checksumFile) : 
			print >> stderr, "=> INFO: Converting the signature file <" + checksumFile + "> to unix format."
			dos2unix(checksumFile) 
		textFile = open(checksumFile, "r")

	if args.dir : chdir( args.dir )

	line = " "
	nbFailedChecksums, nbFilesToCheck, nbUnreadFiles = 0, 0, 0
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

			if not exists( currentFileName) :
				print >> stderr, "sha" + str( method ) + "sum: " + currentFileName + ": No such file or directory"

			effectiveChecksum = calcSHASum(currentFileName,method)
			if effectiveChecksum == expectedChecksum :
				print currentFileName + ": OK"
			elif effectiveChecksum != "" :
				print currentFileName + ": FAILED"
				nbFailedChecksums+=1
			else :
				nbUnreadFiles+=1

			nbFilesToCheck+=1

	if nbUnreadFiles > 0	: print >> stderr, "sha" + str(method) + "sum: WARNING:", nbUnreadFiles    , "of", nbFilesToCheck              , "listed files could not be read"
	if nbFailedChecksums > 0: print >> stderr, "sha" + str(method) + "sum: WARNING:", nbFailedChecksums, "of", nbFilesToCheck-nbUnreadFiles, "computed checksums did NOT match"

	return nbFailedChecksums

def main() :
	initArgs()
	startTime = datetime.now()
	nbFiles=0

	if args.check : verifyChecksums(args.check)
	else :
		if args.recursive :
			chdir( args.dir )
			regExp = "|".join( args.patternList ).replace('?', '.').replace('*', '.*').replace('|', '$|')
			regExp += "$"
#			print >> stderr, "=> regExp = " + regExp
			pattern = re.compile(regExp, re.I)
			for root, dirs, files in walk('.') :
				for file in files :
					filePath = join(root, file)
					if re.search( pattern, file ) :
						hash = calcSHASum( filePath , args.algorithm )
						print hash + " *" + filePath
						nbFiles+=1
		elif args.patternList != "-" :
			for currentGlobbingPattern in args.patternList :
				fileList = glob( currentGlobbingPattern )
				# totalNb = len( fileList )
				for currentFile in fileList :
					hash = calcSHASum( currentFile , args.algorithm )
					print hash + " *" + currentFile
					nbFiles+=1
		else :
			hash = calcSHASum( "-" , args.algorithm )
			print hash + " *" + "-"

#	print >> stderr, "=> The script", scriptBaseName + " took " + str(datetime.now()-startTime) + " to process < " + str( nbFiles ) + " > files."

main()
