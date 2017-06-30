#!/usr/bin/env python
#coding: latin1

import os
from os.path import basename
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser
from sys import stderr, exit, argv
from datetime import datetime

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "fileList", nargs='*', help = "filename list to check, default is stdin / -.", default = '*' )

	global args
	try :    args = parser.parse_args()
	except :
		print >> stderr,  "\n" + parser.format_help()
		exit( -1 )

def main() :
	initArgs()
	startTime = datetime.now()
	nbFiles=0

	for currentGlobbingPattern in args.fileList :
		for currentFile in glob( currentGlobbingPattern ) :
			print currentFile
			nbFiles+=1

	print >> stderr, "=> The script", basename(__file__) + " took " + str(datetime.now()-startTime) + " to process < " + str( nbFiles ) + " > files."

main()
