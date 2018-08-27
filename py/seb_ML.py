#!/usr/bin/env python3

from sys import stdout, stderr, exit
from os import environ

def insideCondaEnv() :
	if environ.get('CONDA_DEFAULT_ENV') is None and environ.get('VIRTUAL_ENV') is None :
		print("=> ERROR: Neither the CONDA_DEFAULT_ENV or VIRTUAL_ENV environment variable is defined: You must be inside a virtual environment to continue.", file = stderr)
		return False
	else : return True

if not insideCondaEnv() : exit(-1)

def mySet_trace(debug = True) :
	if debug :
		try :
			set_trace()
		except Exception as why :
			print("=> WARNING: %s, Importing pdb or ipdb if installed." % why, file= stderr)
			try :
				from ipdb import set_trace #Charge le IPython avec ses startup => shell = TerminalInteractiveShell
			except Exception as why :
				print("=> WARNING: %s, using pdb instead." % why, file= stderr)
				from pdb import set_trace
			set_trace()

import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import pandas as pda
import h5py
from keras import backend as K

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

from string import Template
class DeltaTemplate(Template): # Thanks to https://stackoverflow.com/a/17847006/5649639
	delimiter = '%'

def strfdelta(tdelta, fmt):
	d = {}
	l = {'D': 86400, 'H': 3600, 'M': 60, 'S': 1}
	rem = int(tdelta.total_seconds())

	for k in ( 'D', 'H', 'M', 'S' ):
		if '%'+k in fmt:
			d[k], rem = divmod(rem, l[k])

	t = DeltaTemplate(fmt)
	return t.substitute(**d)

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
	"""
	# If the script is not run by python but by jupyter and is using a different backend then "notebook"
	if mpl.get_backend() != 'Qt5Agg' and mpl.get_backend() != 'nbAgg' :
		PrintInfo("BEFORE: matplotlib backend = <%s>" % mpl.get_backend() )
		mpl.use('nbAgg',warn=False, force=True) # <=> %matplotlib notebook
"""	
	# If the script is not run by python but by jupyter and is using a different backend then "inline"
	if mpl.get_backend() != 'Qt5Agg' and mpl.get_backend() != newBackend :
#		PrintInfo("BEFORE: matplotlib backend = <%s>" % mpl.get_backend() )
		mpl.use( newBackend ,warn=False, force=True ) # <=> %matplotlib inline
#		plt.switch_backend( newBackend ) #Provokes a "AttributeError" in "IPython/core/pylabtools.py#L177"
		import matplotlib.pyplot
#		PrintInfo("AFTER: matplotlib backend = <%s>" % mpl.get_backend() )
	else :
		PrintInfo("matplotlib backend = <%s>\n" % mpl.get_backend() )

def Allow_GPU_Memory_Growth() : #cf. https://github.com/keras-team/keras/issues/1538
	if 'tensorflow' == K.backend():
		import tensorflow as tf
		config = tf.ConfigProto()
		config.gpu_options.allow_growth = True
		config.gpu_options.visible_device_list = "0"
		#session = tf.Session(config=config)
		from keras.backend.tensorflow_backend import set_session
		PrintInfo( "Allowing GPU Memory Growth in tensorflow session config parameters ...\n" )
		set_session(tf.Session(config=config))
		print()
		PrintInfo( "DONE.\n" )

def root_mean_squared_error(y_true, y_pred):
	return K.sqrt(K.mean(K.square(y_pred - y_true), axis=-1))

def showModel(model, modelFileName = "model.png", rankdir = 'TB') :
	if isnotebook() :
		PrintInfo("DISPLAYING MODEL IN SVG :")
		from IPython.display import SVG, display
		from keras.utils.vis_utils import model_to_dot
		display( SVG( model_to_dot( model, show_shapes=True, show_layer_names=True, rankdir = rankdir ).create( prog='dot', format='svg' ) ) )
	else :
		if not modelFileName : modelFileName = "model.svg"
		PrintInfo("DUMPING MODEL TO : " + modelFileName)
		from keras.utils import plot_model
		plot_model(model, to_file=modelFileName, show_shapes=True, show_layer_names=True, rankdir = rankdir)

def copyArgumentsToStructure(args) :
	import argparse
	if not isinstance( args, argparse.Namespace ) :
		PrintError( "args must be of <argparse.Namespace> class type." )
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

def saveDataFrameToFile( df, filename, key = 'df', format = "hdf5" ) :
	if format.lower() == "hdf5" or format.lower() == "h5" :
		PrintInfo( "Dumping <%s> dataframe to <%s> ...\n" % (key,filename) )
		with pda.HDFStore(filename) as store : store[key] = df
	else : PrintError( "The output %s file format is not supported yet." % format )

def loadDataFrameFromFile( filename, key = 'df', format = "hdf5" ) :
	if format.lower() == "hdf5" or format.lower() == "h5" :
		try :
			if isPandasHDF5GeneratedFile( filename ) :
				PrintInfo( "Loading dataframe %s from <%s> ...\n" % (key,filename) )
				with pda.HDFStore(filename, 'r') as store : df = store[key]
			else :
				pathToDataSet = key
				PrintInfo( "Loading HDF5 dataset %s from <%s> and converting it to a pandas' DataFrame ...\n" % (pathToDataSet,filename) )
				with h5py.File(filename, 'r') as f : df = pda.DataFrame( f[pathToDataSet][:] )
			return df
		except Exception as why :
			PrintError( "%s" % why, file = stderr )
			return None
	else :
		PrintError( "The output %s file format is not supported yet." % format )
		return None

def isPandasHDF5GeneratedFile( filename ) :
	isItAPandasHDF5 = False
	try :
		with pda.HDFStore(filename, 'r') as store : isItAPandasHDF5 = 'block0_values' in store.groups()[0]
	except Exception as why :
#		PrintError( "%s" % why, file = stderr )
		isItAPandasHDF5 = False
	return isItAPandasHDF5

def channelsStates2Frequencies( activeChannelsIndex, fmin, fmax, totalNumberOfChannels ) :
	return ( fmin+(fmax-fmin)*activeChannelsIndex/totalNumberOfChannels )

def plotActiveChannels( dfX, dfY, fmin, fmax, activeChannelValue = 1, **kwargs ) :
	if 'marker' in kwargs.keys() :
		marker = kwargs['marker']
	else :
		marker = ''

	fig = plt.figure()
	experimentsRange = dfY.index
	i = 0
	for experiment in experimentsRange :
		sChannelsStates = dfX.loc[experiment] # Current expirement channel states serie
		activeChannelsIndex = sChannelsStates[ sChannelsStates == activeChannelValue ].index # index of active channels
		y = dfY.loc[experiment][ activeChannelsIndex ] # Power of active channels
		frequencies = channelsStates2Frequencies( activeChannelsIndex, fmin, fmax, sChannelsStates.size )
		nbActiveChannels = activeChannelsIndex.size
		plt.plot( frequencies, y, marker = marker, label = dfY.index[i], mew=1.5, ms=6 )
		i += 1
	if 'xlabel' in kwargs.keys() :
		plt.xlabel( kwargs['xlabel'] )
	if 'ylabel' in kwargs.keys() :
		plt.ylabel( kwargs['ylabel'] )
	if 'title' in kwargs.keys() :
		plt.title( kwargs['title'] )
	if 'legend_title' in kwargs.keys() :
		legend_title = kwargs['legend_title']
	else :
		legend_title = ""

	if experimentsRange.size <= 20 :
		leg = plt.legend( loc = 'best', title = legend_title )
#		leg = fig.legend( loc = 'center right', title = legend_title ) #Place the legend outside
		leg.get_frame().set_edgecolor('black')
	plt.grid()

	return fig

def powerOfChannels2PowerInFunctionOfFrequencyOfActiveChannels( dfX, dfY, fMin, fStep, activeChannelValue = 1 ) :
	#Other way to plot the Output power of active channels in function of their frequencies
	nbChannels = dfX.columns.size

	dfActiveChannels = dfX == activeChannelValue
	dfPowerOfActiveChannels = dfY[ dfActiveChannels ].T
	fMax = fMin + fStep * (nbChannels - 1)
	frequencyRange = np.arange( fMin, fMax + fStep, fStep )
	dfPowerOfActiveChannels.index = frequencyRange

	return dfPowerOfActiveChannels

def plotDataFrame( df, **kwargs ) :
	if 'title' in kwargs.keys() :
		df.title = kwargs['title']
	else :
		df.name = ""
	if 'xlabel' in kwargs.keys() :
		df.index.name = kwargs['xlabel']
	if 'legend_title' in kwargs.keys() :
		df.columns.name = kwargs['legend_title']
	else :
		df.columns.name = ""
	if 'marker' in kwargs.keys() :
		marker = kwargs['marker']
	else :
		marker = ''

	ax = df.plot( marker = marker, title = df.title )
	if 'ylabel' in kwargs.keys() :
		ax.set_ylabel( kwargs['ylabel'] )
	nbExperiments = df.columns.size
	if nbExperiments <= 20 :
		leg = ax.legend( loc = 'best', title = df.columns.name )
#		leg = ax.legend( loc = 'center right', title = df.columns.name )
		leg.get_frame().set_edgecolor('black')
	else :
		ax.legend_.remove()
	ax.grid()

	return ax, df
