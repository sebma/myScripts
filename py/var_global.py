#!/usr/bin/env python
#coding: latin1

import sys

global scriptBaseName
scriptBaseName = "var_global.py"

def printNLogMessage(message) :
	functionName = sys._getframe(1).f_code.co_name
	if functionName == "<module>" : functionName = "main"
	message = "[" + scriptBaseName + "][" + functionName + "] - " + message
	print message

def initScript() :
	printNLogMessage( "Message" )
	print "lineno = " + str(sys._getframe().f_lineno)

initScript()
printNLogMessage( "Message Main" )
print "lineno = " + str(sys._getframe().f_lineno)
initScript()
