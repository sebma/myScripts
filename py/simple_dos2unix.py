#!/usr/bin/env python
#coding: latin1

import fileinput, glob, argparse, sys
from sys import stderr

#NE MARCHE PAS COMME ATTENDU SUR WINDOWS

def dos2unix(fmask):
	for line in fileinput.input(glob.glob(fmask), mode="U", inplace=True) :
		print line.rstrip() + "\n",

def unix2dos(fmask):
	for line in fileinput.input(glob.glob(fmask), inplace=True) :
		print line.rstrip() + "\r\n",

def main() :
	parser = argparse.ArgumentParser()
	parser.add_argument( "fileList", nargs='+', help="file list to convert." )
	args = parser.parse_args()
	if   parser.prog == "simple_dos2unix.py" :
		for currentGlobbingPattern in args.fileList : dos2unix( currentGlobbingPattern )
	elif parser.prog == "simple_unix2dos.py" :
		for currentGlobbingPattern in args.fileList : unix2dos( currentGlobbingPattern )

main()
