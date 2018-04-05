#!/usr/bin/env python
#coding: latin1

import os,re
import argparse
from os.path import basename
from subprocess import Popen, check_output, PIPE, call, STDOUT
import sys
from platform import node, python_version_tuple
from sys import stderr, exit, argv
from pdb import set_trace #To add a breakpoint for PDB debugger
import platform
import collections

def initArgs() :
	parser = argparse.ArgumentParser(description='Kill processes according to a given pattern.')
	parser.add_argument( "-l", "--long", help="List the process name as well as the process ID.", action='store_true', default = False )
	parser.add_argument( "-f", "--full", help="The pattern is normally only matched against the process name.  When -f is set, the full command line is used.", action='store_true', default = False )
	# parser.add_argument( "-f", "--force", help="Force process kill", action='store_true', default = False )
	# parser.add_argument( "-y", "--run", help="run in real mode.", action='store_true', default = False )
	# parser.add_argument( "-p", "--pid", type=int, help="pid of process to kill" )
	parser.add_argument( "pattern", help = "Search for PATTERN in each FILE or standard input", default = '.' )

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

def pgrep(regExp) :
	selfPID = str( os.getpid() )
	myPattern = re.compile(regExp, re.I)

	if   os.name == "posix" :
		if platform.system() == "Linux" :
			proc = Popen('pgrep ' + " ".join( args.patternList ) , stdout=PIPE)
			for line in proc.stdout :
				print "line = " + line
		else :
			interpreter = "ksh"
			regExp2 = "."
			if checkPythonVersion(2.7) :
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
		Processes = []

		if isAdmin() :
			wmicProcessProc = Popen("wmic process get caption,commandline,processid -format:csv", stdout=PIPE)
			i = 0
			for line in wmicProcessProc.stdout:
				i += 1
				line = line.strip()
				wmicLineColumns = line.split(separator)
				if not line or wmicLineColumns[0] == "Node" : continue
				if myPattern.search( line ) :
					pid = wmicLineColumns[-1]
					if pid != selfPID :
						process = wmicLineColumns[1]
						command = " ".join( wmicLineColumns[2:-1] )
						p = Process(pid = pid, name = process, commandLine = command, debugData = line)
						Processes.append( p )

		else :
			tasklistProc = Popen('tasklist -fo:csv', stdout=PIPE)
			for line in tasklistProc.stdout :
				line = line.strip()
				tlistLineColumns = line.split(separator)
				if not line or tlistLineColumns[0] == '"Image Name"' : continue
				if myPattern.search( line ) and not tasklistPrompt.search( line ) :
					pid = tlistLineColumns[1].split('"')[1]
					process = tlistLineColumns[0].split('"')[1]
					if pid != selfPID :
						p = Process(pid = pid, name = process, commandLine = "", debugData = line)
						Processes.append( p )

	return Processes

def processName(pid) :
	if   os.name == "posix" :
		proc = Popen('ps -lfp ' + pid , stdout=PIPE)
		for line in proc.stdout :
			print "line = " + line
		print >> stderr, "TO BE DONE !"
	elif platform.system() == "Windows" :
		separator = ","

		if isAdmin() :
			wmicCMDLinePattern = re.compile( "CommandLine" )
			wmicProcessProc = Popen("wmic process where processid=" + pid + " get caption,commandline,processid -format:csv", stdout=PIPE)
			command = ""
			for line in wmicProcessProc.stdout:
				line = line.strip()
				wmicLineColumns = line.split(separator)
				if not line or wmicLineColumns[0] == "Node" : continue
				if pid in line :
					process = wmicLineColumns[1]
					command = wmicLineColumns[2]
					# print "==> command = " + command
					p = Process(pid = pid, name = process, commandLine = command, debugData = line)
			return p
		else :
			tasklistProc = Popen('tasklist -fi "pid eq ' + pid + '" -fo:csv', stdout=PIPE)
			for line in tasklistProc.stdout :
				line = line.strip()
				tlistLineColumns = line.split(separator)
				if not line or tlistLineColumns[0] == '"Image Name"' : continue
				if pid in line :
					process = tlistLineColumns[0].split('"')[1]
					p = Process(pid = pid, name = process, commandLine = "", debugData = line)
					# print "==> process = " + process

			return p

def killProcess(pid, signal=-9) :
	if   os.name == "nt"    :
		retCode = call( "taskkill -t -f -pid " + pid )
	elif os.name == "posix" :
		retCode = call( "kill -9 " + signal )
	if   retCode == 0 :
		if os.name == "posix" : print "=> INFO: Successfully killed process of pid : " + pid
	else :
		print >> stderr, "=> ERROR: The process PID < " + pid + " > could not be killed."

def main() :
	initArgs()
	isAdmin()
	global Process
	Process = collections.namedtuple( 'Process', ['pid', 'name', 'commandLine', 'debugData'] )

	# for regExp in  :
	ProcessList = pgrep(args.pattern)
	# print "=> MAIN :\n"
	for process in ProcessList :
		try :
			if   scriptBaseName == "pgrep.py" :
				print "%4d" % int(process.pid),
				if args.long :
					if args.full and process.commandLine :
						print process.commandLine,
					else :
						print process.name,
				print
			elif scriptBaseName == "pkill.py" : killProcess( process.pid )
		except :
			print "=> ERROR: debugData = " + process.debugData

	if len(ProcessList) == 0 : exit(1)

main()
