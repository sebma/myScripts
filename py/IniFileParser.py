#!/usr/bin/env python
#coding: latin1

import collections
from datetime import datetime
import os
from shutil import copy2
from sys import stderr, exc_info
import re
from pdb import set_trace #To add a breakpoint for PDB debugger

class Section : #Classe section qui contient uniquement le dictionnaire des parametres
	def __init__(self, linesOfSection) :
		self.separator = ParameterFileParser.separator
		self.parameters = collections.OrderedDict()
		self.spaceChar = ""
		cpt = 0
		for line in linesOfSection :
			if self.separator not in line :
				self.parameters[ "empty_line_" + str(cpt) ] = line
				cpt += 1
			else :
				if self.separator + " " in line : self.spaceChar = " "
				if len( line.split(self.separator) ) == 1 :
					self.parameters[ line.split(self.separator)[0].rstrip() ] = ""
				else :
					self.parameters[ line.split(self.separator)[0].rstrip() ] = self.separator.join( line.split(self.separator)[1:] )

	def getAttribute(self, key) :
		if "empty_line_" in key : return self.parameters[ key ]
		else :
			try:
				value = self.parameters[ key ]
				if value[0] == self.spaceChar :
					return key + self.spaceChar + self.separator + value
				else :
					return key + self.separator + value
			except :
				print >> stderr, "=> ERROR %s : %s." % ( exc_info()[0], exc_info()[1] )

	def setAttribute(self, key, value) :
		if   value == None :
			self.parameters[ key ] = self.spaceChar + '""'
		elif len(value) == 0 :
			self.parameters[ key ] = self.spaceChar
		else :
			lastkey = self.parameters.keys()[-1]
			if "empty_line_" in lastkey : #Si la ligne precedente est vide, on la supprime
				lastLine = self.parameters[ lastkey ]
				self.parameters.popitem( last = True )
				self.parameters[ key ] = self.spaceChar + value
				self.parameters[ lastkey ] = lastLine #On remet la ligne vide apres le nouveau parametre
			else :
				self.parameters[ key ] = self.spaceChar + value

	def delAttribute(self, key) :
		del self.parameters[ key ]

	def toConsole(self) :
		for key in self.parameters.keys() :
			print self.getAttribute(key)

	def getSection(self) :
		return self

	def toFile(self, fileHandle, newlineChar) :
		for key, value in self.parameters.items() :
			if "empty_line_" in key :
				fileHandle.write(value + newlineChar)
			else :
				if len(value) and value[0] == self.spaceChar :
					fileHandle.write(key + self.spaceChar + self.separator + value + newlineChar)
				else :
					fileHandle.write(key + self.separator + value + newlineChar)

class SectionFile : #Classe qui contient un dictionnaire de sections
	def __init__(self) :
		self.sections = collections.OrderedDict() #Dictionnaire de sections

	def addSection(self, linesOfSection) :
		#Referencement de la section dans la liste des sections avec son nom
		self.sections[ linesOfSection[0] ] = Section( linesOfSection[1:] )

	def setAttribute(self, sectionName, key, value) :
		if sectionName in self.sections :
			self.sections[ sectionName ].setAttribute( key, value )
		else :
			# Ajout d'une nouvelle section au dictionnaires de sections
			self.sections[ sectionName ] = Section( [ key + ParameterFileParser.separator + value ] )

	def getAttribute(self, sectionName, key) :
		if sectionName in self.sections :
			return self.sections[ sectionName ].getAttribute( key )
		else :
			return None

	def setAttributeOfSections(self, sectionPattern, key, value) :
		sectionPatternRegExp = re.compile( re.escape( sectionPattern ), re.I )
		for sectionName in self.sections :
			if sectionPatternRegExp.search(sectionName) :
				self.sections[ sectionName ].setAttribute( key, value )

	def delAttribute(self, sectionName, key) :
		self.sections[ sectionName ].delAttribute(key)

	def delSection( self, sectionName) :
		del self.sections[ sectionName ]

	def getSection(self, sectionName) :
		try :
			return self.sections[ sectionName ]
		except :
			print >> stderr, "=> ERROR %s : %s." % ( exc_info()[0], exc_info()[1] )

	def toConsole(self) :
		for sectionName, section in self.sections.items() :
			print sectionName 
			section.toConsole()

	def toFile(self, fileName, newlineChar, no_backup) :
		if not no_backup :
			try :
				iniFileNameBackup = fileName.split(os.extsep)[0] + "_" + datetime.now().strftime('%Y.%m.%d-%Hh%Mm%Ss') + os.extsep + fileName.split(os.extsep)[1]
				copy2(fileName,iniFileNameBackup)
			except IOError as why :
				print >> stderr, "Unable to copy file :" + str(why)
				exit(4)
			else :
				print "=> Copy " + fileName + " -> " + iniFileNameBackup + " ... Done."

		with open(fileName,"wb") as fileHandle :
			for sectionName, section in self.sections.items() :
				fileHandle.write( sectionName + newlineChar )
				section.toFile(fileHandle, newlineChar)

class ParameterFileParser : #Classe de fichier de parametres
	separator = '=' #Variable static
	def __init__(self, fileName) :
		if 'OrderedDict' not in dir( collections ) :
			print >> stderr, "=> ERROR: You must use python 2.7 minimum version to use the 'OrderedDict' data structure."
			exit(1)

		self.fileName = fileName
		self.sectionFile = SectionFile()
		self.spaceChar = ""
		try :
			with open(self.fileName, "rU") as fileHandle :
				lineBlock = []
				for line in fileHandle :
					if ParameterFileParser.separator + " " in line : self.spaceChar = " "
					line = line.rstrip("\n") #On supprime le caractere de fin de line
					if len( line.strip() ) and line.strip()[0] == '[' : # Prochaine section rencontre
						if len( lineBlock ) : # Si la section precedente est non vide
							self.sectionFile.addSection( lineBlock ) #Enregistrement de la section precedente
						lineBlock = [ line ] #Premiere ligne de la nouvelle section
					else :
						lineBlock += [ line ]
				self.sectionFile.addSection(lineBlock) #Enregistrement de la derniere section
		except IOError as why :
			print >> stderr, "%s." % why
			exit(1)

	def setAttribute(self, section, key, value="") :
		if '*' in section :
			section = section.strip('*')
			self.sectionFile.setAttributeOfSections(section, key, value)
		else :
			self.sectionFile.setAttribute(section, key, value)

	def getAttribute(self, section, key) :
		return self.sectionFile.getAttribute(section, key)

	def delAttribute(self, section, key) :
		self.sectionFile.delAttribute(section, key)

	def delSection(self, section) :
		self.sectionFile.delSection(section)

	def getSection(self, section) :
		return self.sectionFile.getSection(section)

	def toConsole(self) :
		self.sectionFile.toConsole()

	def getNewlineChar(self, fileName) :
		with open(self.fileName, "rU") as fileHandle :
			fileHandle.readline()
			fileHandle.readline()
			self.newlineChar = fileHandle.newlines

	def toFile(self, no_backup = False) :
		self.getNewlineChar(self.fileName)
		self.sectionFile.toFile(self.fileName, self.newlineChar, no_backup)
