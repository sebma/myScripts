#!/usr/bin/env python
#coding: latin1
import os, sys
from os import chdir, walk, fdopen
import re
from os.path import basename, dirname, isdir, isfile, join
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser
from sys import stderr, exit, argv
from datetime import datetime
from pdb import set_trace #To add a breakpoint for PDB debugger

def initArgs() :
	parser = ArgumentParser(description = 'Print selected parts of lines from each FILE to standard output.')
	parser.add_argument( "-d","--delimiter", help=" use DELIM instead of TAB for field delimiter", default = '\t' )
	parser.add_argument( "-f","--fields", help="output only these fields;  also print any line\n\t\tthat contains no delimiter character, unless\n\t\t\tthe -s option is specified" )
	parser.add_argument( "fileList", nargs='*', help = "Print selected parts of lines from each FILE to standard output.", default = '-' )

	global args, scriptBaseNames
	scriptBaseName = parser.prog
	args = parser.parse_args()

#	try :    args = parser.parse_args()
#	except :
#		print >> stderr,  "\n" + parser.format_help()
#		exit( -1 )

def cut( file, sep, start, stop) :
	if file == '-' : textfile = sys.stdin
	else :			textfile = open(file)

	if start is None :
		for line in textfile :
			print args.delimiter.join(line.split(args.delimiter)[:stop])
	elif stop is None :
		for line in textfile :
			print args.delimiter.join(line.split(args.delimiter)[start:])
	else :
		for line in textfile :
			print args.delimiter.join(line.split(args.delimiter)[start:stop])

	if file != '-' : textfile.close()

def splitFieldList( file, sep, fields ) :
	if   fields.startswith('-') :
		end = int(fields.split('-')[1])
		cut( file, sep, None, end )
	elif fields.endswith('-') :
		begin = int(fields.split('-')[0]) - 1
		cut( file, sep, begin, None )
	else :
		if   '-' in fields :
			begin = int(fields.split('-')[0]) - 1
			end = int(fields.split('-')[1])
			cut( file, sep, begin, end )
		elif ',' in fields :
			fieldList = map( int, fields.split(',') )

			if file == '-' : textfile = sys.stdin
			else :			textfile = open(file)

			for line in textfile :
				print line.split(args.delimiter)[fieldList[0]-1],
				for field in fieldList[1:] :
					print args.delimiter + line.split(args.delimiter)[field-1],

			if file != '-' : textfile.close()
			print
		else :
			begin = int(fields) - 1
			end = begin + 1
			cut( file, sep, begin, end )

def main() :
	initArgs()
	startTime = datetime.now()

	if args.fileList == '-' :
		splitFieldList( '-', args.delimiter, args.fields )
	else :
		for currentGlobbingPattern in args.fileList :
			if isdir( currentGlobbingPattern ) : currentGlobbingPattern += os.sep + '*'
			for currentFile in glob( currentGlobbingPattern ) :
				if isfile(currentFile) :
					splitFieldList( currentFile, args.delimiter, args.fields )

main()
