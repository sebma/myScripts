#!/usr/bin/env python3

from sys import stdout, stderr, exit
from os import environ

def insideCondaEnv() :
	if environ.get('CONDA_DEFAULT_ENV') is None and environ.get('VIRTUAL_ENV') is None :
		print("=> ERROR: Neither the CONDA_DEFAULT_ENV or VIRTUAL_ENV environment variable is defined: You must be inside a virtual environment to continue.", file=stderr)
		return False
	else : return True

if not insideCondaEnv() : exit(-1)

from pdb import set_trace
#from ipdb import set_trace #Charge le IPython avec ses startup => shell = TerminalInteractiveShell
import matplotlib as mpl
import matplotlib.pyplot as plt
import pandas as pda
from keras import backend as K

def isnotebook() :
	if notebookInterpreter() == "Jupyter" :
		return True
	else :
		return False

def notebookInterpreter() :
	try :
		from IPython import get_ipython
		shell = get_ipython().__class__.__name__
		if shell == 'ZMQInteractiveShell':
			# Jupyter notebook or qtconsole
			interpreter = "Jupyter"
		elif shell == 'TerminalInteractiveShell':
			# Terminal running IPython
			interpreter = "IPython"
		else :
			# Terminal running Python
			interpreter = "Python"
	except NameError as why :
		print( "=> ERROR: %s" % why, file = stderr )
		# Probably standard Python interpreter
		interpreter = "UNKNOWN"

#	print( "=> interpreter = <%s>\n" % interpreter )
	return interpreter

def setJupyterBackend( newBackend = 'nbAgg' ) : # Set the "notebook" backend as default or other when newBackend is given
	# If the script is not run by python but by jupyter and is using a different backend then "notebook"
	#if mpl.get_backend() != 'Qt5Agg' and mpl.get_backend() != 'nbAgg' :
	#	print("=> BEFORE: matplotlib backend = <%s>" % mpl.get_backend() )
	#	mpl.use('nbAgg',warn=False, force=True) # <=> %matplotlib notebook
	# If the script is not run by python but by jupyter and is using a different backend then "inline"
	if mpl.get_backend() != 'Qt5Agg' and mpl.get_backend() != newBackend :
		print("=> BEFORE: matplotlib backend = <%s>" % mpl.get_backend() )
		mpl.use( newBackend ,warn=False, force=True ) # <=> %matplotlib inline
#		plt.switch_backend( newBackend ) #Provokes a "AttributeError" in "IPython/core/pylabtools.py#L177"
		import matplotlib.pyplot
		print("=> AFTER: matplotlib backend = <%s>" % mpl.get_backend() )
	else :
		print("=> matplotlib backend = <%s>" % mpl.get_backend() )

def Print(*args, quiet = False, **kwargs) :
	if not quiet : print(*args, **kwargs)

def PrintError(*args, quiet = False, **kwargs) :
	if not quiet :
		print( "=> ERROR: ", end="", file = stderr )
		print(*args, **kwargs, file = stderr)

def PrintWarning(*args, quiet = False, **kwargs) :
	if not quiet :
		print( "=> WARNING: ", end="", file = stderr )
		print(*args, **kwargs, file = stderr)

def PrintInfo(*args, quiet = False, **kwargs) :
	if not quiet :
		print( "=> INFO: ", end="", file = stderr )
		print(*args, **kwargs, file = stderr)

def Exit(retCode=0, markdown=False) :
	if markdown : Print("</code></pre>")
	exit(retCode)

def Allow_GPU_Memory_Growth() : #cf. https://github.com/keras-team/keras/issues/1538
	if 'tensorflow' == K.backend():
		import tensorflow as tf
		config = tf.ConfigProto()
		config.gpu_options.allow_growth = True
		config.gpu_options.visible_device_list = "0"
		#session = tf.Session(config=config)
		from keras.backend.tensorflow_backend import set_session
		PrintInfo( "=> Allowing GPU Memory Growth in tensorflow session config parameters ...\n" )
		set_session(tf.Session(config=config))
		PrintInfo( "=> DONE.\n" )

def root_mean_squared_error(y_true, y_pred):
	return K.sqrt(K.mean(K.square(y_pred - y_true), axis=-1))

def showModel(model, modelFileName = "model.png", rankdir = 'TB') :
	if isnotebook() :
		PrintInfo("=> DISPLAYING MODEL IN SVG :")
		from IPython.display import SVG, display
		from keras.utils.vis_utils import model_to_dot
		display( SVG( model_to_dot( model, show_shapes=True, show_layer_names=True, rankdir = rankdir ).create( prog='dot', format='svg' ) ) )
	else :
		if not modelFileName : modelFileName = "model.svg"
		PrintInfo("=> DUMPING MODEL TO : " + modelFileName)
		from keras.utils import plot_model
		plot_model(model, to_file=modelFileName, show_shapes=True, show_layer_names=True, rankdir = rankdir)

def copyArgumentsToStructure(args) :
	import argparse
	if not isinstance( args, argparse.Namespace ) :
		PrintError( "=> ERROR: args must be of <argparse.Namespace> class type." )
		Exit(5)

#	from collections import namedtuple # namedtuples are not mutable
	from collections import OrderedDict
	from namedlist import namedlist

	argsDict = OrderedDict( sorted( args.__dict__.items() ) )

	argListString = ' '.join( argsDict.keys() )
	tupleOfValues = tuple( argsDict.values() )

	myStruct = namedlist( "myStruct", argListString )

	myArgs = myStruct( *tupleOfValues )

	return myArgs

def saveDataframe( df, filename, key = 'df', format = "hdf5" ) :
	if format == "hdf5" :
		PrintInfo( "=> Dumping <%s> dataframe to <%s> ...\n" % (key,filename) )
		with pda.HDFStore(filename) as store : store[key] = df
	else : PrintError( "=> ERROR : The output %s file format is not supported yet." % format )

def loadDataframe( filename, key = 'df', format = "hdf5" ) :
	if format == "hdf5" :
		PrintInfo( "=> Loading dataframe from <%s> ...\n" % filename )
		with pda.HDFStore(filename, 'r') as store : df = store[key]
		return df
	else : PrintError( "=> ERROR : The output %s file format is not supported yet." % format )

def channelsStates2Frequencies( activeChannelsIndex, fmin, fmax, totalNumberOfChannels ) :
	return ( fmin+(fmax-fmin)*activeChannelsIndex/totalNumberOfChannels )

def plotExperments( dfX, dfY, fmin, fmax ) :
	fig = plt.figure()
	experimentsRange = dfY.index
	for experiment in experimentsRange :
		sChannelsStates = dfX.loc[experiment] # Current expirement channel states serie
		activeChannelsIndex = sChannelsStates[ sChannelsStates == 1 ].index # index of active channels
		y = dfY.loc[experiment][ activeChannelsIndex ] # Power of active channels
		frequencies = channelsStates2Frequencies( activeChannelsIndex, fmin, fmax, sChannelsStates.size )
		nbActiveChannels = activeChannelsIndex.size
		plt.plot( frequencies, y, marker='x', label='%d Ch' % nbActiveChannels, mew=1.5, ms=6 )
	plt.xlabel( 'Frequency (THz)' )
	plt.ylabel( 'Power (dBm)' )
	plt.title( 'Output optical power' )
#	plt.legend( loc='best' )
	leg = fig.legend( loc='center right' )
	leg.get_frame().set_edgecolor('black')
	plt.grid()
