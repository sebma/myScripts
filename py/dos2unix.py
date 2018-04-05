#!/usr/bin/env python
#coding: latin1

import sys, glob, string, argparse
from sys import stderr

def dos2unix(fmask):
	for fname in glob.glob(fmask) :
		with open(fname,"rb") as fp : text = fp.read()
		with open(fname,"wb") as fp : fp.write(text.replace('\r\n','\n'))

def unix2dos(fmask):
	for fname in glob.glob(fmask) :
		with open(fname,"rb") as fp : text = fp.read()
		if string.find(text,'\r') < 0 :
			with open(fname,"wb") as fp : fp.write(text.replace('\n','\r\n'))

def main() :
	parser = argparse.ArgumentParser(description='DOS to Unix and vice versa text file format converter')
	parser.add_argument( "fileList", nargs='+', help="file list to convert." )
	args = parser.parse_args()
	if   parser.prog == "dos2unix.py" :
		for currentGlobbingPattern in args.fileList : dos2unix( currentGlobbingPattern )
	elif parser.prog == "unix2dos.py" :
		for currentGlobbingPattern in args.fileList : unix2dos( currentGlobbingPattern )

main()
