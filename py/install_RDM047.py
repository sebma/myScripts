#!/usr/bin/env python
#coding: latin1

import sys #Pour : argv
from sys import stderr, exit
from platform import node, uname
#import os #Pour: getenv, chdir, getcwd
from os import getenv, chdir, getcwd, mkdir, makedirs, removedirs, system
from os.path import exists, basename, dirname, splitext
from shutil import copy2, rmtree
import datetime #Pour: today, now
import hashlib #Pour: md5, sha1, sha224, sha256, sha384, sha512
from zipfile import ZipFile, BadZipfile
#import re #Pour : match

def md5sum(filename) :
	textFile = open(filename, "rb")
	h = hashlib.md5()

	#On lit le fichier par blocks de 4ko qu'on concatene a l'objet m de type 'hashlib'
	while True:
		data = textFile.read(4*1024*1024)
		if not data: break
		h.update(data)

	hashed = h.hexdigest()
	return hashed

def calcChecksum(filename, method) :
	fileHandle = open(filename, "rb")
	if   method == "md5"  : h = hashlib.md5()
	elif method == "sha1" : h = hashlib.sha1()
	elif method == "sha224" : h = hashlib.sha224()
	elif method == "sha256" : h = hashlib.sha256()
	elif method == "sha384" : h = hashlib.sha384()
	elif method == "sha512" : h = hashlib.sha512()

	#On lit le fichier par blocks de 4ko qu'on concatene a l'objet m de type 'hashlib'
	while True:
		data = fileHandle.read(4*1024*1024)
		if not data: break
		h.update(data)

	hashed = h.hexdigest()
	fileHandle.close()
	return hashed

def verifyChecksums(checksumFile) :
	textFile = open(checksumFile, "rt")

	line = " "
	nbFailedChecksums = 0
	nbChecksums = 0
	while line != "" :
		line = textFile.readline()
		if   line == ""   : break #readline renvoie une chaine vide si la fin de fichier a ete rencontree
		elif line == "\n" : continue

		line = line.strip()
		if line != "" and line[0] != "#" :
			expectedChecksum = line.split()[0]
			currentFileName = line.split()[1]
			if currentFileName[0] == '*' : currentFileName = currentFileName[1:]

			nbChars = len( expectedChecksum )
			if nbChars == 40 : method = 1
			else : method = nbChars*4

			effectiveChecksum = calcChecksum(currentFileName,method)
			if effectiveChecksum == expectedChecksum :
				print currentFileName + ": OK"
			else :
				print currentFileName + ": FAILED"
				nbFailedChecksums+=1
			nbChecksums+=1

	if nbFailedChecksums > 0 : print >> stderr, "sha" + str(method) + "sum: WARNING:",nbFailedChecksums,"of",nbChecksums, "computed checksums did NOT match"

	return nbFailedChecksums

def initMain() :
	global dirSeparator, operatingSystem, initialWorkDir
	print
	initialWorkDir = getcwd()

	operatingSystem = uname()[0]
	if operatingSystem == "Windows" : dirSeparator = "\\"
	elif operatingSystem == "Linux" : dirSeparator = "/"
	elif operatingSystem.startswith( "CYGWIN" ) : dirSeparator = "/"

	global hostname
	hostname = node().upper()

	hostnamePrefix = hostname[0]

	global environment

	if	 hostnamePrefix == 'D' or hostnamePrefix == 'M' : environment = "DEV"
	elif hostnamePrefix == 'H' : environment = "HOMOL"
	elif hostnamePrefix == 'P' : environment = "PROD"
	else : environment = "UNKNOWN"

	today = datetime.date.today() #Permet de recuperer la date courrante
	now = datetime.datetime.now() #Permet de recuperer l'heure courrante

	global year
	year = today.strftime('%Y')
	global month
	month = today.strftime('%m')
	global day
	day = today.strftime('%d')

	hour=now.hour
	min=now.minute
	sec=now.second

	global scriptBaseName
	scriptBaseName = basename(__file__)
	scriptBaseNamePrefix = splitext(basename(__file__))[0]
	global logFileName, logDir
	logFileName = splitext(basename(__file__))[0] + "_" + year + month + day + ".log"
	logDir = initialWorkDir + dirSeparator + "log"
	if not exists(logDir) : mkdir(logDir)

	global program_name
	program_name="Cicl0021.exe"
	rc=0
	global ELSAG_HOME
	ELSAG_HOME="D:\Produits\Elsag"
	controlFile="RDM047.sha"
	global zipFileName
	#zipFileName="RDM047_BAD.zip"
	#zipFileName="RDM047_GOOD.zip"

def printNWriteMessage(filename,message) :
	fileHandle = open( filename, "a")
	print message
	print >> fileHandle, message

def printNLogMessage(message) :
	logFileHandle = open( logDir + dirSeparator + logFileName, "a")
	message = "=> INFO: " + message
	print message
	print >> logFileHandle, message

def printNLogError(error) :
	logFileHandle = open( logDir + dirSeparator + logFileName, "a")
	error = "=> ERROR: " + error + "\n"
	print >> stderr, error
	print >> logFileHandle, error

def readZIPFile(filename) :
	if not exists (filename) : printNLogError( "The file " + filename + " does not exist." )

	try:
		with ZipFile(filename) as zipFile :
			zipFileList = zipFile.namelist()

		return zipFileList
	except BadZipfile as e:
		printNLogErrorAndExit( str(e), -3 )


def runSQL( sqlScript ) :
	if exists( sqlScript ) :
		printNLogMessage("sqlplus -s ISIB/ISIB@dmildmil @sql" + dirSeparator + sqlScript + " ...")
		printNLogMessage( system("sqlplus -s ISIB/ISIB@dmildmil @sql" + dirSeparator + sqlScript))
	else : printNLogError("The SQL script <" + sqlScript + "> does not exist.")

def main() :
	initMain()

	printNLogMessage("DEBUT du script <" + scriptBaseName + ">\n")
	printNLogMessage( "operatingSystem = " + operatingSystem)
	printNLogMessage( "dirSeparator = " + dirSeparator)
	printNLogMessage( "environment = " + environment + "\n" )

	system32DIR = dirname(getenv("COMSPEC"))
#	toolList = [ "tail.exe", "unzip.exe" ]
	toolList = []
	for tool in toolList :
		if not exists ( system32DIR + dirSeparator + tool) :
			copy2( tool, system32DIR)

	argc = len(sys.argv)
	if argc == 1 :
		printNLogError("=> Usage: <" + scriptBaseName + "> <fichier.zip>")
		exit(1)

	zipFileName = sys.argv[1]

	rniHome = ELSAG_HOME + dirSeparator + "rni" + dirSeparator
	printNLogMessage( "rniHome = " + rniHome + "\n")
#	chdir ( rniHome )
	if not exists( rniHome + "server" + dirSeparator + "Arch" ) :
		printNLogMessage("Creating directories server" + dirSeparator + "Arch ...")
		makedirs( rniHome + "server" + dirSeparator + "Arch" )
	else :
		if exists (rniHome + "server" + dirSeparator + program_name) :
			printNLogMessage("Sauvegarde du binaire <" + program_name + "> dans server" + dirSeparator + "Arch" + dirSeparator + program_name + "-" + year + month + day)
			copy2( rniHome + "server" + dirSeparator + program_name, rniHome + "server" + dirSeparator + "Arch" + dirSeparator + program_name + "-" + year + month + day )

	if not exists(rniHome + "tests") :
		printNLogMessage("Creating directory: <" + rniHome + "tests>\n")
		os.mkdir( rniHome + "tests" )

	chdir ( initialWorkDir )
	regularFileList = []
	binaryFileList = []
	zipFileList = readZIPFile( zipFileName )
	for zipFileElem in zipFileList :
		if zipFileElem[-1] != "/" :
			#Recuperation des elements de type "fichier"
			regularFileName = zipFileElem
			regularFileList.append(regularFileName)
			if regularFileName.lower().endswith("exe") :
				#Recuperation des elements de type "executable"
				binaryFileList.append(regularFileName)

	printNLogMessage( "Ouverture du fichier <" + zipFileName + "> ..." )
	zipFile = zipfile.ZipFile(zipFileName)

	tmpDIR = getenv("TMP") + dirSeparator + "tmp"
	if not exists(tmpDIR) : mkdir(tmpDIR)
	printNLogMessage("Extraction de tous les fichiers de l'archive <" + zipFileName + "> pour verifier leurs checksums ...\n")
	zipFile.extractall(tmpDIR)

	chdir(tmpDIR)
	chechSumMethod = "sha512"
	zipCheckSumFile = initialWorkDir + dirSeparator + splitext(zipFileName)[0]+"." + chechSumMethod
	printNLogMessage("zipCheckSumFile = " + zipCheckSumFile + "\n")
	nbBadChecksums = 0
	if not exists(zipCheckSumFile) :
		zipCheckSumFileHandle = open( zipCheckSumFile, "w")
		for regularFileName in regularFileList :
			printNWriteMessage( zipCheckSumFile,  calcChecksum(regularFileName, chechSumMethod) + "  " + regularFileName )
		#close(zipCheckSumFileHandle)
	else :
		nbBadChecksums=verifyChecksums( zipCheckSumFile, chechSumMethod)
	
	print
	if nbBadChecksums > 0 :
		printNLogError("Some checksum are bad")
		exit(128)

	printNLogMessage("Suppression des fichiers temporaires dans: " + tmpDIR)
	print

	chdir( initialWorkDir )
	rmtree( tmpDIR )

	for binaryFileName in binaryFileList :
		binaryBaseName = basename(binaryFileName).lower()
		if   binaryBaseName == "cicl0021.exe"	 :
			printNLogMessage( "Traitement pour le binaire: <" + binaryBaseName + "> ..." )
			printNLogMessage( "Extraction du binaire <" + binaryFileName + "> dans <" + ELSAG_HOME + "> ..." )
			zipFile.extract( binaryFileName, ELSAG_HOME )
		elif binaryBaseName == "f24.exe"		 :
			printNLogMessage( "Traitement pour le binaire: <" + binaryBaseName + "> ..." )
		elif binaryBaseName == "scaricoacnc.exe" :
			printNLogMessage( "Traitement pour le binaire: <" + binaryBaseName + "> ..." )
		else :
			print "Non trouve."

	printNLogMessage("Extraction de tous les elements de <" + zipFileName + "> dans <" + ELSAG_HOME + "> ...")
	zipFile.extractall( ELSAG_HOME )
	zipFile.close()

	print

	sqlScript1 = "AggDb_RDM047.sql"
	sqlScript2 = "insertPATH_XML_SG.sql"

	chdir ( rniHome + "sql" )
	#runSQL( sqlScript1 )
	#runSQL( sqlScript2 )
	chdir ( ".." )

	printNLogMessage( "logFileName = " + logDir + dirSeparator + logFileName )
	printNLogMessage( "FIN du script <" + scriptBaseName + ">" )

main()
