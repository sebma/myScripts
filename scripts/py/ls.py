#!/usr/bin/env python
#coding: latin1
import os
from os import chdir, walk, getenv
import re
from os.path import basename, isdir, join, getsize, getmtime
from glob import glob #Filename Globbing patterns
from argparse import ArgumentParser, RawTextHelpFormatter
from sys import stderr, exit, argv
from datetime import datetime
from pdb import set_trace #To add a breakpoint for PDB debugger
from subprocess import Popen, PIPE
from time import strftime, localtime, mktime
from stat import *
from math import log

def printf(format, *args) : 
	print format % args,
	if os.name == "posix" : stdout.flush()

def getCurrentUser() :
	if   os.name == "nt" :
		user = getenv("USERDOMAIN") + os.sep + getenv("USERNAME")
	elif os.name == "posix" :
		from os import getlogin
		user = getlogin()

	return user

def _get_terminal_size_windows():
	try:
		from ctypes import windll, create_string_buffer
		import struct
		# stdin handle is -10
		# stdout handle is -11
		# stderr handle is -12
		h = windll.kernel32.GetStdHandle(-12)
		csbi = create_string_buffer(22)
		res = windll.kernel32.GetConsoleScreenBufferInfo(h, csbi)
		if res:
			(bufx, bufy, curx, cury, wattr,
			left, top, right, bottom,
			maxx, maxy) = struct.unpack("hhhhHhhhhhh", csbi.raw)
			sizex = right - left + 1
			sizey = bottom - top + 1
			return sizex, sizey
	except:
		pass

def _get_terminal_size_tput():
	try:
		cols = int( Popen( 'tput  cols'.split(), stdout=PIPE ).communicate()[0] )
		rows = int( Popen( 'tput lines'.split(), stdout=PIPE ).communicate()[0] )
		return (cols, rows)
	except:
		pass

def termSize() :
	if   os.name == "nt" :
		return _get_terminal_size_windows()
	elif os.name == "posix" :
		return _get_terminal_size_tput()

def initArgs() :
	parser = ArgumentParser(description = 'List information about the FILEs (the current directory by default).', formatter_class=RawTextHelpFormatter )
	parser.add_argument( "fileList", nargs='*', help = "filename list to check, default is *.", default = '*' )
	parser.add_argument( "-R","--recursive", help="list subdirectories recursively", action='store_true', default = False )
	parser.add_argument( "-r","--reverse", help="reverse order while sorting", action='store_true', default = False )
	parser.add_argument( "-1", "--one", help="list one file per line", action='store_true', default = False )
	parser.add_argument( "-l", "--long", help="use a long listing format.", action='store_true', default = False )
	parser.add_argument( "-hr", "--human-readable", help="with -l, print sizes in human readable format.", action='store_true', default = False )
	parser.add_argument( "-C", "--cols", help="list entries by columns.", action='store_true', default = True )
	parser.add_argument( "-x", "--lines", help="list entries by lines instead of by columns.", action='store_true', default = False )
	parser.add_argument( "-n", "--numeric-uid-gid", help="like -l, but list numeric user and group IDs.", action='store_true', default = False )
	parser.add_argument( "-d", "--directory", help="list directory entries instead of contents", action='store_true', default = False )
	parser.add_argument( "-F", "--classify", help="append indicator (one of */=>@|) to entries", action='store_true', default = False )
	parser.add_argument( "-i", "--inode", help="print the index number of each file", action='store_true', default = False )
	parser.add_argument( "-t", "--mtime", help="sort by modification time", action='store_true', default = False )
	parser.add_argument( "-S", help="sort by file size", action='store_true', default = False )
	parser.add_argument( "--full-time", help="like -l --time-style=full-iso", action='store_true', default = False )
	parser.add_argument( "--time-style",
		help="with -l, show times using style STYLE:"
		+ os.linesep
		+ "full-iso, long-iso, iso, locale, +FORMAT."
		+ os.linesep
		+ "FORMAT is interpreted like `date'; if FORMAT is"
		+ os.linesep
		+ "FORMAT1<newline>FORMAT2, FORMAT1 applies to"
		+ os.linesep
		+ "non-recent files and FORMAT2 to recent files;"
	)

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

	if args.time_style == "full-iso" : args.full_time = True
	if   args.lines :
		args.cols  = False
		args.long  = False
		args.one   = False
	elif args.long :
		args.cols  = False
		args.lines = False
		args.one   = False
	elif args.one :
		args.cols  = False
		args.lines = False
		args.long  = False
	elif   args.cols : #Parametre par default
		args.lines = False
		args.long  = False
		args.one   = False

	if scriptBaseName.startswith( "ll" ) : args.long = True
	if scriptBaseName == "llh.py" : args.human_readable = True

def GetOwner(filename):
	import win32security
	f = win32security.GetFileSecurity(filename, win32security.OWNER_SECURITY_INFORMATION)
	(username, domain, sid_name_use) =  win32security.LookupAccountSid(None, f.GetSecurityDescriptorOwner())
	return username

def dateOfFile( file, strftimeFomat = "%Y%m%d" ) :
	# return strftime( strftimeFomat, localtime( getmtime( file ) ) )
	return datetime.fromtimestamp( getmtime( file ) ).strftime( strftimeFomat )

def octal2perms(mode) :
	perms = ['-'] * 11
	perms[0] = '-'
	perms[1] = 'r' if mode & S_IRUSR else '-'
	perms[2] = 'w' if mode & S_IWUSR else '-'
	perms[3] = ('s' if mode & S_IXUSR else 'S') if mode & S_ISUID else ('x'if mode & S_IXUSR else '-')
	perms[4] = 'r' if mode & S_IRGRP else '-'
	perms[5] = 'w' if mode & S_IWGRP else '-'
	perms[6] = ('s' if mode & S_IXGRP else 'S') if mode & S_ISGID else ('x' if mode & S_IXGRP else '-')
	perms[7] = 'r' if mode & S_IROTH else '-'
	perms[8] = 'w' if mode & S_IWOTH else '-'
	perms[9] = ('t' if mode & S_IXOTH else 'T') if mode & S_ISVTX else ('x' if mode & S_IXOTH else '-')
	perms[10] = ' '

	return "".join(perms)

def humanReadable(size) :
	if size <= 0 : size = "%7d" % 0
	else :
		units = [ "", "K", "M", "G", "T", "P", "E", "Z", "Y" ]
		devider = int( log(size,1024) )
		size = size * 1.0 / 1024**devider

		if devider == 0 :
			size = "%7d" % size
		else :
			size = "%6.2f" % size

		size += units[ devider ]

	return size

def ll(file) :
	myStat = os.stat(file)
	mode = myStat.st_mode

	fileRepresentation = file
	if os.name == "posix" :
		if   S_ISREG(mode) :
			perms = "-"
		elif S_ISBLK(mode) :
			perms = "b"
		elif S_ISCHR(mode) :
			perms = "c"
		elif S_ISDIR(mode) :
			perms = "d"
			if args.classify : fileRepresentation += os.sep
		elif S_ISLNK(mode) :
			perms = "l"
			if args.classify : fileRepresentation += "@"
		elif S_ISFIFO(mode) :
			perms = "p"
			if args.classify : fileRepresentation += "|"
		elif S_ISSOCK(mode) :
			perms = "s"
			if args.classify : fileRepresentation += "="
	elif os.name == "nt" :
		if   S_ISREG(mode) :
			perms = "-"
		elif S_ISDIR(mode) :
			perms = "d"
			if args.classify : fileRepresentation += os.sep

	# Si c'est un fichier executable
	if args.classify and S_ISREG(mode) and int( str(mode)[-1] ) % 2 : fileRepresentation += "*"

	perms += octal2perms(mode)[1:]

	size = myStat.st_size
	if args.human_readable :
		size = humanReadable(size)
	else :
		size = "%s" % size

	output = ""
	if   args.full_time  : timeFormat = "%Y-%m-%d %X.%f %z"
	elif args.time_style :
		if   args.time_style == "full-iso" :
			timeFormat = "%Y-%m-%d %X.%f %z"
		elif args.time_style == "long-iso" :
			timeFormat = "%Y-%m-%d %H:%M"
		elif args.time_style == "iso" :
			timeFormat = "%m-%d %H:%M"
		else :
			timeFormat = args.time_style
	else : timeFormat = "%Y-%m-%d %H:%M"

	if args.inode :
		if os.name == "posix" : output = "%s " % myStat.st_ino

	if args.numeric_uid_gid :
		output += "%s %d %s %d %s %s %s" % ( perms, myStat.st_nlink, str(myStat.st_uid), myStat.st_gid, size, dateOfFile(file, timeFormat), fileRepresentation )
	else :
		if   os.name == "posix" :
			from pwd import getpwuid
			owner = getpwuid(myStat.st_uid).pw_name
		elif os.name == "nt" :
			# owner = GetOwner(file)
			owner = getCurrentUser().split(os.sep)[1]
		output += "%s %d %s %d %s %s %s" % ( perms, myStat.st_nlink, owner, myStat.st_gid, size, dateOfFile(file, timeFormat), fileRepresentation )

	print output

def lsInCols(files) :
	pass

def initScript() :
	if   os.name == "posix" : from pwd import getpwuid
	elif os.name == "nt" : pass

def main() :
	initArgs()
	initScript()
	width, height = termSize()
	startTime = datetime.now()
	nbFiles = 0
	previous = "."
	nbCols = 0
	if args.recursive :
		if isdir(args.fileList[0]) :
			chdir(args.fileList[0])
			regExp = "|".join( args.fileList[1:] ).replace('?', '.').replace('*', '.*').replace('|', '$|')
		else :
			regExp = "|".join( args.fileList ).replace('?', '.').replace('*', '.*').replace('|', '$|')
		regExp += "$"
		# print "=> regExp = " + regExp
		pattern = re.compile(regExp, re.I)
		for root, dirs, files in walk('.', topdown = not args.reverse) :
			nbFilesInDir = 0
			if not args.long and not args.one :
				print root + ":"
				nbSubDirs = 0
				totSubDirs = len(dirs)
				for subDir in dirs :
					print subDir + "\t",
					nbSubDirs +=1
					if not nbSubDirs % nbCols or nbSubDirs == totSubDirs : print

			if   args.reverse :
				subDirFileList = reversed(files)
			else :
				subDirFileList = files

			for file in subDirFileList :
				currentFile = join(root, file)
				if pattern.search( file ) :
					if   args.long :
						ll(currentFile)
					elif args.one :
						print currentFile
					else :
						pass
						# if previous == root :
							# print file + "\t\t",
							# nbFilesInDir += 1
							# if not nbFilesInDir % nbCols : print
				previous = root
			if not args.one : print
	else :
		for currentGlobbingPattern in args.fileList :
			if isdir( currentGlobbingPattern ) :
				if not args.directory :
					currentGlobbingPattern += os.sep + '*'

			fileList = glob( currentGlobbingPattern )
			if   args.mtime :
				fileList = sorted(fileList, key=getmtime, reverse=True)
			elif args.S :
				fileList = sorted(fileList, key=getsize , reverse=True)

			if args.reverse :
				fileList = fileList[::-1]

			nbFiles = len(fileList)
			colPos = 0
			length = 0

			if nbFiles == 0 :
				print >> stderr, scriptBaseName + ": " + currentGlobbingPattern + ": No such file or directory"
				exit(2)

			if   args.lines : nbCols  = int(height/nbFiles)+1
			elif args.cols  : nbLines = int(width /nbFiles)+1

			if   args.one :
				for currentFile in fileList : print currentFile
			elif args.long :
				for currentFile in fileList : ll(currentFile)
			elif args.lines :
				colPos = 0
				for currentFile in fileList :
					print currentFile + "\t",
					colPos +=1
					length += len(currentFile)
					# if not colPos % nbCols or nbSubDirs == totSubDirs : print
					if not colPos % nbCols or length >= width:
						print
						# print >> stderr, "length = " + str(length)
						length = 0
			elif args.cols :
				colPos = 0
				for currentFile in fileList :
					print currentFile + "\t",
					colPos +=1
					length += len(currentFile)
					# if not colPos % nbCols or nbSubDirs == totSubDirs : print
					if not colPos % nbLines or length >= width:
						print
						# print >> stderr, "length = " + str(length)
						length = 0

	# print "\n"
	# print "=> nbFiles= " + str(nbFiles)
	# print "=> nbCols = " + str(nbCols)
	# print "=> width  = " + str(width)
	# print "=> height = " + str(height)

main()
