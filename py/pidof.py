#!/usr/bin/env python
#coding: latin1

import os,re
import argparse
from subprocess import Popen, PIPE, call, STDOUT
import sys
from sys import stderr, exit, argv
from platform import node, python_version_tuple
from pdb import set_trace #To add a breakpoint for PDB debugger
import platform

def initArgs() :
	parser = argparse.ArgumentParser(description='Kill processes according to a given pattern.')
	parser.add_argument( "-s", "--single", help="Single shot - this instructs the program to only return one pid.", action='store_true', default = False )
	parser.add_argument( "-o", "--omit", nargs='?', help = "Tells pidof to omit processes with that process id." )
	# parser.add_argument( "-x", "--scripts", help="Scripts too - this causes the program to also return process id's of shells running the named scripts.", action='store_true', default = False )
	parser.add_argument( "patternList", nargs='+', help = "Search for PATTERN in each FILE or standard input", default = '.' )

	global scriptBaseName, args
	scriptBaseName = parser.prog
	args = parser.parse_args()

def checkPythonVersion( minimalVersion=2.6 ) :
	currentVersion = float( python_version_tuple()[0] + '.' + ''.join( python_version_tuple()[1:] ) )
	if currentVersion < minimalVersion :
		print >> stderr,  "=> ERROR: The minimum version needed for Python is <" + str(minimalVersion) + "> but you have the version <" + str(currentVersion) + ">" + " installed in < " + sys.prefix + " > on server <" + node() + ">.\n"
		return 1
	else :
		return 0

def isAdmin() :
	if   os.name == "nt" :
		retCode = call( "net session", stdout=open(os.devnull), stderr=STDOUT )
	elif os.name == "posix" :
		print >> stderr, "TO BE DONE !"

	if not retCode :return True
	else :			return False

def pidof(regExp) :
	selfPID = str( os.getpid() )
	myPattern = re.compile(regExp, re.I)

	PIDs = []
	if   os.name == "posix" :
		if platform.system() == "Linux" :
			proc = Popen('pgrep ' + " ".join( args.patternList ) , stdout=PIPE)
			for line in proc.stdout :
				print "line = " + line
		else :
			interpreter = "ksh"
			if checkPythonVersion(2.7) :
				from subprocess import check_output
				outPut = check_output( "ps -elf | grep " + regExp, shell=True )
				for line in outPut :
					print "line = " + line
			else :
				proc1 = Popen('ps -elf', stdout=PIPE)
				proc =  Popen('grep ' + regExp, stdin=proc1.stdout, stdout=PIPE)
				for line in proc.stdout :
					print "line = " + line
			print >> stderr, "TO BE DONE !"
	elif platform.system() == "Windows" :
		interpreter = "cmd"
		regExp2 = "Prompt \- "
		tasklistPrompt = re.compile(regExp2)
		separator = ","

		if isAdmin() :
			wmicProcessProc = Popen("wmic process get caption,commandline,processid -format:csv", stdout=PIPE)
			for line in wmicProcessProc.stdout:
				line = line.strip()
				wmicLineColumns = line.split(separator)
				if not line or wmicLineColumns[0] == "Node" : continue
				if myPattern.search( line ) :
					pid = wmicLineColumns[-1]
					if pid != selfPID :
						PIDs.append( pid )
		else :
			tasklistProc = Popen('tasklist -fo:csv', stdout=PIPE)
			for line in tasklistProc.stdout :
				line = line.strip()
				tlistLineColumns = line.split(separator)
				if not line or tlistLineColumns[0] == '"Image Name"' : continue
				if myPattern.search( line ) and not tasklistPrompt.search( line ) :
					pid = tlistLineColumns[1].split('"')[1]
					if pid != selfPID :
						PIDs.append( pid )

	return PIDs

def main() :
	initArgs()
	isAdmin()
	nbProcesses = 0
	for regExp in args.patternList :
		PIDsList = pidof(regExp)
		nbProcesses += len(PIDsList)
		if args.single :
			print PIDsList[0],
		else :
			for pid in PIDsList :
				if pid != args.omit :
					print pid,

	if nbProcesses == 0 : exit(1)
	else : print; exit(0)

main()
