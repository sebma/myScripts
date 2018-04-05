#!/usr/bin/env python
#coding: latin1
import fileinput, glob, sys, argparse
parser = argparse.ArgumentParser()
parser.add_argument( "fileList", nargs='+', help="file list to convert." )
args = parser.parse_args()
for pattern in sys.argv[1:] :
	for line in fileinput.input(glob.glob(pattern), inplace=True) :
		line = line.rstrip() + "\n"
		print line,
