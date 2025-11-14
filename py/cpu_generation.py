#!/usr/bin/env python
import subprocess
import re
import sys
import ipdb

# https://www.intel.com/content/www/us/en/support/articles/000032203/processors/intel-core-processors.html

argc = len(sys.argv)
if argc == 1:
	modelLine = subprocess.check_output("grep -m1 'model name' /proc/cpuinfo", shell=True).decode()
	model_name = re.search(': (.*)', modelLine).group(1).strip()
elif argc == 2:
	modelLine = sys.argv[1]
	try :
		model_name = re.search(': (.*)', modelLine).group(1).strip()
	except AttributeError :
		model_name = modelLine

print("CPU Model: %s " % model_name)

# Infer generation
if re.search(r'i[0-9]+-[0-9]+', model_name):
	modelNumber = re.search(r'i[0-9]+-([0-9]+)', model_name).group(1)  # Capture modelNumber
#	ipdb.set_trace()
	if len(modelNumber) >= 4:
		generation = modelNumber[0:2]
	else:
		generation = modelNumber[0]
	print("Intel Generation: %s" % generation)
elif re.search(r'Ryzen\ ([0-9]+)', model_name):
	generation = re.search(r'Ryzen\ ([0-9]+)', model_name).group(1)  # Capture generation for AMD
	print("AMD Ryzen Generation: %s (e.g., Ryzen 5 5600X is from the %sth generation)" %(generation[0],generation[0]))
else:
	print("Unknown CPU model format.")
