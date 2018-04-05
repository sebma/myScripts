#!/usr/bin/env DYLD_LIBRARY_PATH=/Applications/PicoScope6.app/Contents/Resources/lib python2
from __future__ import division, absolute_import, print_function, unicode_literals
# coding: utf-8

"""
See http://www.picotech.com/document/pdf/ps2000apg.en-6.pdf for PS2000A models:
PicoScope 2205 MSO
PicoScope 2206
PicoScope 2206A
PicoScope 2206B
PicoScope 2207
PicoScope 2207A
PicoScope 2208
PicoScope 2208A
"""

#MODULES STANDARDS
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from sys import exit
import os, sys
from os import environ
from os.path import isdir
import platform
from datetime import datetime
from math import floor, log10
from time import sleep

#MODULES A INSTALLER
import picoscope
from picoscope import *
#import pylab as plt
import numpy as np
#import scipy.io as sio #Pour exporter des fichiers au format Matlab < 7.3 != hdf5

def powerise10(x):
	""" Returns x as a*10**b with 0 <= a < 10
	"""
	if x == 0: return 0,0
	Neg = x < 0
	if Neg: x = -x
	a = 1.0 * x / 10**(floor(log10(x)))
	b = int(floor(log10(x)))
	if Neg: a = -a
	return a,b

def eng(x):
	"""Return a string representing x in an engineer friendly notation"""
	a,b = powerise10(x)
	if -3 < b < 3: return "%.4g" % x
	a = a * 10**(b % 3)
	b = b - b % 3
	return "%.4ge%s" % (a,b)

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"
	yearMonthDay = datetime.today().strftime('%Y%m%d')

	parser = ArgumentParser( description = 'Picoscope Acquisition program.', formatter_class=ArgumentDefaultsHelpFormatter )
	required = parser.add_argument_group('required arguments')

#	required.add_argument( "-t", "--timeGate", help="Time gate.", type=float, required = True )
	required.add_argument( "-t", "--timeGate", help="Time gate.", type=float )
	parser.add_argument( "-s", "--samplingInterval", help="Set the sampling interval.", type=float, default = 0 )
	parser.add_argument( "-d", "--dir", help="TO DO: Directory to write the data to.", default=yearMonthDay + os.sep )
	parser.add_argument( "-p", "--pattern", help="TO DO: Exported datafile name pattern.", default="data-*.txt" )
	parser.add_argument( "-n", "--nbFiles", help="TO DO: Number of waveforms to acquire", type=int, default = 1 )
	parser.add_argument( "-m", "--nbSamples", help="Number of samples to read", type=float, default = 0 )
	parser.add_argument( "-P", "--picoscopeInfo", help="Print picoscope hardware info.", action='store_true', default = False )
	parser.add_argument( "-v", "--verbosity", help="Increase output verbosity (e.g., -vv is more than -v).", action='count', default = 0 )
	parser.add_argument( "-V", "--version", help="Print version info.", action='store_true', default = False )
#	parser.add_argument( "-V", "--version", help="Print version info.", action='version', version = '%(prog)s version ' + __version__ )
	parser.add_argument( "-D", "--debug", help="Debug the program with pdb or ipdb (if available).", action='store_true', default = False )
	parser.add_argument( "--mdh",  help="Print help in markdown code blocks.", action='store_true', default = False )
	parser.add_argument( "--md", help="Print output in markdown code blocks.", action='store_true', default = False )

	scriptBaseName = parser.prog
	arguments = parser.parse_args()

	if arguments.mdh :
		print("<pre><code>")
		parser.print_help()
		print("</code></pre>")
		exit()

	if arguments.md : print("<pre><code>")

def mySet_trace() : #Pour l'environement de DEV
	if arguments.debug : #Pour l'environement de DEV
		try :
			from ipdb import set_trace
		except Exception as why :
			print("=> WARNING: %s, using pdb instead.\n" % why,file=sys.stderr)
			from pdb import set_trace
		set_trace()
	else :
		pass

def initScript() :
	global today, yearMonthDay
	today = datetime.today()
	yearMonthDay = today.strftime('%Y%m%d')
	global picoscopePATHS
	picoscopePATHS = picoscope.__path__

	global pythonVersion
	pythonVersion = ".".join(map(str, sys.version_info[:3]))

	print("%s version %s" % (scriptBaseName,__version__) )

	if arguments.verbosity >= 3 :
		print("=> Current environment variables loaded :\n")
		for key,value in sorted(environ.items()) :
			if 'BASH_FUNC_' not in key :
				print("=> %s = %s" %(key,value))
		print()

	if arguments.version :
		if arguments.verbosity :
			print("=> Using Picoscope python module from %s" % picoscopePATHS[0],end="")
#			printExternalModulesVersions()
			if arguments.verbosity >= 2 :
				try :
					print(" version : %s." % picoscope.__version__)
				except AttributeError :
					import pkg_resources
					print(" version : %s." % pkg_resources.get_distribution("picoscope").version )
				if __doc__ : print(__doc__)
				print("\nUsing Python version %s" % sys.version )
				print("Python  : " + sys.executable)
			else :
				print("\nUsing Python version %s" % pythonVersion )
		exit()

	if not arguments.picoscopeInfo :
		if arguments.timeGate :
			if arguments.samplingInterval :
				arguments.nbSamples = arguments.timeGate / arguments.samplingInterval
			elif arguments.nbSamples :
				arguments.samplingInterval = arguments.timeGate / arguments.nbSamples
			else :
				print("=> ERROR: You must specify either a sampling Interval or a number of samples.", file=sys.stderr)
				exit(1)
		else :
			print("=> ERROR: You must first give a time gate.", file=sys.stderr)
			exit(2)

	if platform.system() == 'Darwin' :
		if 'DYLD_LIBRARY_PATH' in environ.keys() :
			if arguments.verbosity : print("=> DYLD_LIBRARY_PATH = %s" % environ['DYLD_LIBRARY_PATH'])
		else :
			print("=> ERROR : DYLD_LIBRARY_PATH is not set, setting it ...", file=sys.stderr)
			if isdir('/Applications/PicoScope6.app/Contents/Resources/lib') :
				environ['DYLD_LIBRARY_PATH'] = '/Applications/PicoScope6.app/Contents/Resources/lib'
				print("=> DYLD_LIBRARY_PATH = %s" % environ['DYLD_LIBRARY_PATH'])
			else :
				exit(3)
	elif platform.system() == 'Linux' :
		if environ['LD_LIBRARY_PATH'] :
			if arguments.verbosity : print("=> LD_LIBRARY_PATH = %s" % environ['LD_LIBRARY_PATH'])
		else :
			print("=> ERROR : LD_LIBRARY_PATH is not set, setting it ...", file=sys.stderr)
			if isdir('/opt/picoscope/lib') :
				environ['LD_LIBRARY_PATH'] = '/opt/picoscope/lib'
				print("=> LD_LIBRARY_PATH = %s" % environ['LD_LIBRARY_PATH'])
			else :
				exit(3)

def main() :
	initArgs()
	initScript()

	if arguments.verbosity == 2 :
		print(__doc__)

	if arguments.verbosity :
		print("=> Using Picoscope python module from %s" % picoscopePATHS[0],end="")
		try :
			print(" version : %s." % picoscope.__version__)
		except AttributeError :
			import pkg_resources
			print(" version : %s." % pkg_resources.get_distribution("picoscope").version )
#	else : print()

	print("=> Attempting to open Picoscope ...")

	try :
		ps = ps2000a.PS2000a()
		"""
	except :
		ps = ps2000.PS2000()
	except :
		ps = ps3000.PS3000()
	except :
		ps = ps3000a.PS3000a()
	except :
		ps = ps4000.PS4000()
	except :
		ps = ps4000a.PS4000a()
	except :
		ps = ps5000a.PS5000a()
	except :
		ps = ps6000.PS6000()
"""
	except IOError as why :
		if 'PICO_NOT_FOUND' in str(why) :
			print("=> ERROR: No PicoScope XXXX could be found.", file=sys.stderr)
			exit(-1)
		else :
			print(why, file=sys.stderr)
			exit(-2)

	print("=> Found the following picoscope: %s" % ps.getUnitInfo('VariantInfo') )
	if arguments.picoscopeInfo :
		if arguments.verbosity :
			print( ps.getAllUnitInfo() )
		ps.close()
		exit()
#	else :
#		print("=> Found the following picoscope: %s" % ps.getUnitInfo('VariantInfo') )

	try :
		if arguments.verbosity :
			print("=> INFO : timeGate = %s s" % arguments.timeGate)
			print("=> INFO : samplingInterval = %s s" % eng(arguments.samplingInterval))
			print("=> INFO : nbSamples = %s" % arguments.nbSamples)

#		waveform_desired_duration = 50E-6
		waveform_desired_duration = arguments.timeGate
		obs_duration = 2 * waveform_desired_duration
#		sampling_interval = obs_duration / 4096
		sampling_interval = arguments.samplingInterval

		(actualSamplingInterval, nSamples, maxSamples) = \
		    ps.setSamplingInterval(sampling_interval, obs_duration)
		print("waveform_desired_duration = %s s" % eng(waveform_desired_duration))
		print("obs_duration = %s s" % eng(obs_duration))
		print("Sampling interval = %s s" % eng(sampling_interval))

		print("ActualSampling interval = %Lf ns" % (actualSamplingInterval * 1E9))
		print("Taking  samples = %d" % nSamples)
		print("Maximum samples = %d" % maxSamples)

		# the setChannel command will chose the next largest amplitude
		channelRange = ps.setChannel('A', 'DC', 2.0, 0.0, enabled=True, BWLimited=False)
		print("Chosen channel range = %d" % channelRange)

		ps.setSimpleTrigger('A', 1.0, 'Falling', timeout_ms=100, enabled=True)

		#AWG : Arbitrary Waveform Generator
		ps.setSigGenBuiltInSimple(offsetVoltage=0, pkToPk=1.2, waveType="Sine", frequency=50E3)

		ps.runBlock()
		ps.waitReady()
		print("Waiting for awg to settle.")
		sleep(2.0)
		ps.runBlock()
		ps.waitReady()
		print("Done waiting for trigger")
		dataA = ps.getDataV('A', nSamples, returnOverflow=False)

		dataTimeAxis = np.arange(nSamples) * actualSamplingInterval
	except IOError as why :
		print(why, file=sys.stderr)
	finally :
		ps.stop()
		ps.close()

	#Uncomment following for call to .show() to not block
	#plt.ion()
	"""
    plt.figure()
    plt.hold(True)
    plt.plot(dataTimeAxis, dataA, label="Clock")
    plt.grid(True, which='major')
    plt.title("Picoscope 2000 waveforms")
    plt.ylabel("Voltage (V)")
    plt.xlabel("Time (ms)")
    plt.legend()
    plt.show()
"""

	if arguments.md : print("</code></pre>")

if __name__ == "__main__":
	main()
