#!/usr/bin/env python
#coding: latin1
import os, sys
from os import listdir, chdir, getcwd, makedirs
from os.path import getmtime, exists, splitext, basename, isfile
from time import strftime, localtime
from shutil import move
from sys import stdout, stderr, exit
from platform import python_version_tuple
import re
import argparse
from datetime import datetime

def printNLogString(logHandle, string) :
	print >> logHandle, string
	print string

def printf(format, *args) : 
	print format % args,
	if os.name == "posix" : stdout.flush()

def main() :
	nbFiles = 0
	previous = 0.0
	logFile = splitext( basename( __file__ ) )[0] + datetime.now().strftime("_%Y%m%d_%HH%M") + ".txt"

	parser = argparse.ArgumentParser()
	parser.add_argument("-d", "--dir", default='.', help="select the dir to scan.")
	parser.add_argument("-r", "--regExp", default='.', help="regular expression to select the files to be moved.")
	args = parser.parse_args()

	previousDir = getcwd()
	try :
		chdir( args.dir )
	except :
		print >> stderr, "=> This directory " + args.dir + " does not exist."
		exit(1)

	with open( logFile , 'w' ) as logHandle :
		begin=datetime.now()
		pattern = re.compile(args.regExp, re.I)
		printNLogString( logHandle, "=> Counting the files to be processed in the directory <" + args.dir + begin.strftime('> at %X on the %d/%m/%Y') + " ..." )
		totalNumberOfFiles = len( [name for name in os.listdir( '.' ) if re.search( pattern, name ) and isfile(name)] )
		end=datetime.now()
		printNLogString( logHandle, "=> Total number of files = " + str( totalNumberOfFiles ) )
		printNLogString( logHandle, "=> It took : " + str(end-begin) + " to count the files.\n" )
		if totalNumberOfFiles != 0 :
			printf( "=>   0.0%%" )
			for fileBaseName in listdir( '.' ) :
				if re.search( pattern, fileBaseName ) :
					fileYearMonthDay = strftime('%Y%m%d', localtime(getmtime(fileBaseName) ) )
					fileYearMonth = fileYearMonthDay[:-2]
					fileYear = fileYearMonthDay[:-4]
					destination = fileYear + os.sep + fileYearMonth + os.sep + fileYearMonthDay
					if not exists( destination ) : makedirs( destination )
					print >> logHandle, "=> Moving < " + fileBaseName + " > into < " + destination + " ..."
					move( fileBaseName, destination )
					nbFiles+=1
					percentile = nbFiles *100.0/totalNumberOfFiles
					if percentile - previous > 0.1 :
						remain = totalNumberOfFiles - nbFiles
						printf( "\b" * 6 + "%4.1f%%", percentile )
						previous = percentile
			print
			end=datetime.now()
			printNLogString( logHandle, "=> It took : " + str(end-begin) + " to run.\n" )
			printNLogString( logHandle, "=> " + str(nbFiles) + " files were moved" + end.strftime(' at %X on the %d/%m/%Y.') + "\n")

	print >> stderr, "=> See the log file: " + logFile + "."
	chdir( previousDir )

main()
