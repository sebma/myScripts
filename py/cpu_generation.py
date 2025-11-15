#!/usr/bin/env python
#coding: latin1

import subprocess
import re
import sys
import pdb

# https://www.intel.com/content/www/us/en/support/articles/000032203/processors/intel-core-processors.html

progName = sys.argv[0]
argc = len(sys.argv)
if argc == 1:
	#modelLine = subprocess.check_output("grep -m1 'model name' /proc/cpuinfo", shell=True).decode()
	pattern1 = re.compile( 'model name', re.I )
	pattern2 = re.compile( ': (.*)' )
	cpuinfoFile = open("/proc/cpuinfo")
	for line in cpuinfoFile :
		if pattern1.search( line ) :
			model_name = re.search( pattern2, line).group(1).strip()
			break
	cpuinfoFile.close()
elif argc == 2:
	modelLine = sys.argv[1]
	pattern2 = re.compile( ': (.*)' )
	try :
		model_name = re.search( pattern2, modelLine).group(1).strip()
	except AttributeError :
		model_name = modelLine
else :
	sys.stderr.write("=> Usage : %s [cpuModel]\n" % progName)
	exit(1)

print("CPU Model: %s " % model_name)
#pdb.set_trace()

# Infer generation
pattern3 = re.compile( r'i[0-9]+-([0-9]+)' )
intel_match = re.search(pattern3, model_name)
if intel_match :
	modelNumber = intel_match.group(1)  # Capture modelNumber
	generation = modelNumber[0:len(modelNumber)-3]
	print("Intel Generation: %s" % generation)
else :
	pattern4 = re.compile( r'Ryzen\ ([0-9]+)' )
	amd_match = re.search( pattern4, model_name)
	if amd_match :
		generation = amd_match.group(1)  # Capture generation for AMD
		print("AMD Ryzen Generation: %s (e.g., Ryzen 5 5600X is from the %sth generation)" %(generation[0],generation[0]))
	else:
		print("Unknown CPU model format.")
