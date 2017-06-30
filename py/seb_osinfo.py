#!/usr/bin/env python
#coding: latin1

import os,sys,platform

print
print "=> OS platform.platform = " , platform.platform()
print "=> OS platform.processor = " , platform.processor()
print "=> OS platform.architecture = " , platform.architecture()
print "=> OS platform.node = " , platform.node()
print "=> SYS Version = " , sys.version

if sys.platform == "linux" : print "USER = "  , os.getenv("USER")
elif sys.platform == "win32": print "windir = ", os.getenv("windir")

if "Windows-XP" in platform.platform() :  print "=> Windows XP"
elif "Windows-2003" in platform.platform() :  print "=> Windows 2003"
elif "Linux" in platform.platform() :  print "=> Linux"

print "Nom de la fonction appellee = ", __name__
print
raw_input("Press Enter to continue...")

exit(5)
