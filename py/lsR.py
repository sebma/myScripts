#!/usr/bin/env python
#coding: latin1

import os
from argparse import ArgumentParser
from os import chdir
from sys import stderr
from datetime import datetime
from pdb import set_trace #To add a breakpoint for PDB debugger

def printf(format, *args) : 
	print format % args,
	if os.name == "posix" : stdout.flush()

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "fileList", nargs='*', help = "filename list to check, default is stdin / -.", default = "-" )
	parser.add_argument( "-r","--recursive", help="read files in text mode (default on Unix/Linux)", action='store_true', default = False )
	parser.add_argument( "-d", "--dir", help="extract files into exdir.", default="." )

	global args
	try :    args = parser.parse_args()
	except :
		print >> stderr,  "\n" + parser.format_help()
		exit( -1 )

def main() :
	initArgs()
	begin=datetime.now()
#	root, dirs, files = os.walk('.').next()
#	for file in files : print "=> Filename = " + os.path.join(root, file)

	chdir( args.dir )
	for root, dirs, files in os.walk('.') :
		for file in files :
			print "=> Filename = " + os.path.join(root, file)
			#pass
	end=datetime.now()
	print >> stderr, str( end-begin )

main()
