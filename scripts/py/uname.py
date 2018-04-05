#!/usr/bin/env python
#coding: latin1
import os
import sys
import platform
import socket

print "=> os.name = " + os.name
if os.name == "posix" : print "=> os.uname()[1] = " + os.uname()[1]
print "=> sys.platform = " + sys.platform
print "=> platform.platform() = " + platform.platform()
print "=> platform.system() = " + platform.system()
print "=> platform.uname() = " + str( platform.uname() )
print "=> platform.uname()[0] = " + platform.uname()[0]
print "=> platform.uname()[1] = " + platform.uname()[1]
print "=> platform.node() = " + platform.node()
print "=> socket.gethostname() = " + socket.gethostname()

raw_input("Press Enter to continue...")
