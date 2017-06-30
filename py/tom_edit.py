#!/usr/bin/env python
#coding: latin1

import argparse
import ConfigParser
from sys import argv, stderr, exit
import sys
from platform import node, python_version, python_version_tuple
from os import getenv, chdir, getcwd, mkdir, makedirs, removedirs, system, times
from os.path import exists, basename, dirname, splitext, abspath, relpath
import os
import re
import datetime #Pour: today, now
import random #Pour: randint
from shutil import copy2, rmtree, move
from subprocess import Popen, check_output, PIPE
from pdb import set_trace #To add a breakpoint for PDB debugger
import inspect

def isUnixScript(fileName) :
	fileHandle = open(fileName,"rb")
	if "\r\n" in fileHandle.read() :
		print >> stderr, "=> ERROR: You must convert the script < " + fileName + " > to UNIX format so it can be run on both Windows and UNIX/Linux."
		fileHandle.close()
		exit(1)
	else :
		fileHandle.close()

def printNLogInfo(message) :
	logFileHandle = open( logFileName, "a" )
	if message :
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.datetime.now().strftime('%H:%M:%S') + str(datetime.datetime.now().microsecond)
		timestamp = str(datetime.datetime.now())[11:23]
		message = timestamp + " - [" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - " + message

	print message
	print >> logFileHandle, message
	logFileHandle.close()

def printNLogError(error) :
	if error :
		logFileHandle = open( logFileName, "a")
		callerFunctionName = inspect.stack()[1][3]

	#	timestamp = datetime.datetime.now().strftime('%H:%M:%S') + str(datetime.datetime.now().microsecond)
		timestamp = str(datetime.datetime.now())[11:23]
		error = timestamp + " - [" + pid + "][" + scriptBaseName + "][" + callerFunctionName + "] - ERROR: " + error
		print >> stderr, error
		print >> logFileHandle, error
		logFileHandle.close()

def initLog() :
	funcName = inspect.stack()[0][3]
	initDates()

	global logBaseDir, logFileName
	logBaseDir = getcwd()

	if not logBaseDir :
		print >> stderr, "=> ERROR: The variable <RCV_LOG_DIR> is not defined."
		exit(1)

	logDir = logBaseDir + os.sep + yearMonth + os.sep + yearMonthDay
	if not exists(logDir) : makedirs(logDir)
	global scriptBaseName
	scriptBaseName = basename(__file__)
	logFileName = logDir + os.sep + splitext( scriptBaseName )[0] + "_" + yearMonthDay + ".log"

	global pid
	pid = str( os.getpid() )

	printNLogInfo( "Lancement du script < " + scriptBaseName + " > dont le PID est < " + pid + " >." )

def initDates() :
	global yearMonth, yearMonthDay
	today = datetime.date.today()
	year = today.strftime('%Y')
	month = today.strftime('%m')
	day = today.strftime('%d')
	yearMonth = today.strftime('%Y%m')
	yearMonthDay = today.strftime('%Y%m%d')

def initScript() :
	isUnixScript(__file__)
	global dataMountPoint
	if os.name == "nt" : dataMountPoint = "D:"
	elif os.name == "posix" : dataMountPoint = "/d"

	initDates()
	initLog()
	funcName = inspect.stack()[0][3]
	printNLogInfo( "Continuing function <" + funcName + "> ..." )

	env=node()[0]
	parser = argparse.ArgumentParser()
	parser.add_argument("iniFile", help="filename to edit")
	parser.add_argument("-s", "--section", help="select the section in the ini file", required=True)
	parser.add_argument("-p", "--parameter", help="select the parameter in the ini file", required=True)
	parser.add_argument("-v", "--value", help="select the value in the ini file", required=True)
	args = parser.parse_args()
	print args.iniFile
	print args.section
	print args.parameter
	print args.value

	if   env == "D" : configParameter = "RCV_CFG_DEV"
	elif env == "H" : configParameter = "RCV_CFG_HOMO"
	elif env == "P" : configParameter = "RCV_CFG_PROD"

	printNLogInfo( "The arguments passed to < " + scriptBaseName + " > are:\n" + str(argv[1:]) )

	exit(0)
	set_trace()
	global TRN, SFN, SPN, srcFileName, fileBaseName
	TRN, SFN, direction, SPN, srcFileName, TRC, PRC, fileBaseName = argv[1:]
	if not exists( srcFileName ) : printNLogErrorAndExit( "The sourcefile < " + srcFileName + " > does not exists anymore.", -2 )

	global isProd
	if SPN in lstExpPartProd : isProd = True
	else : isProd = False

	global archDir
	archDir = dirname(srcFileName) + os.sep + "Arch" + os.sep + yearMonth + os.sep + yearMonthDay
	for dir in [ archDir ] :
		if not exists(dir) : makedirs(dir)

	global appCode, application
	appCode = fileBaseName.split(".")[2]
	if appCode[1:4] == "WPG" :
		application = "PHARE"
	elif appCode[1:4] == "ALI" :
		application = "ALISE"
	else :
		application = "UNKNOWN"

def main() :
	initScript()
	retCode = 0

	exit( retCode)

main()
