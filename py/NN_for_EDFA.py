#!/usr/bin/env python3

orig_keys = set(globals().keys())

from seb_ML import *
print("")

import pandas as pda
import numpy as np
import matplotlib.pyplot as plt
import os
from glob import glob
from datetime import datetime
from ipdb import set_trace #Charge le IPython avec ses startup => shell = TerminalInteractiveShell

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	import argparse
	class MyFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.MetavarTypeHelpFormatter):
		pass

#	parser = argparse.ArgumentParser( description = 'Regresssion with Keras.', formatter_class = argparse.ArgumentDefaultsHelpFormatter )
	parser = argparse.ArgumentParser( description = 'Regresssion with Keras.', formatter_class = MyFormatter )

	group = parser.add_mutually_exclusive_group()
	group.add_argument( "dataFileName", help="(Optional) data fileName to read data from.", nargs='?', type=str )

	parser.add_argument( "-b", "--batch_size", help="batchSize taken from the whole dataSet.", default=-1, type=float )
	parser.add_argument( "-e", "--epochs", help="Number of epochs to go through the NN.", default=500, type=float )
	parser.add_argument( "--f0", help="Starting frequency.", default=191.7, type=float )
	parser.add_argument( "--fStep", help="Frequency step.",  default=0.05, type=float )
	parser.add_argument( "-E", "--earlyStoppingPatience", help="Number of epochs before stopping once your loss starts to increase (disabled by default).", default=-1, type=int )
	parser.add_argument( "-P", "--plotMetrics", help="Enables the live ploting of the trained model metrics in Jupyter NoteBook.", action='store_true', default = False )
	group.add_argument( "-d", "--dataDIR", help="Datasets directory", type=str )
	parser.add_argument( "-p", "--pattern", help="Data file name pattern.", default="data*.txt", type=str )
#	parser.add_argument( "-D", "--dumpedModelFileName", help="Dump the model image to fileName", default = None, type=str )
	parser.add_argument( "-S", "--shuffle", help="Shuffle the data along the way.", action='store_true', default = False )
	parser.add_argument( "-V", "--validation_split", help="Validation split ratio of the whole dataset.", default=0.2, type=float )
	parser.add_argument( "-v", "--verbosity", help="Increase output verbosity (e.g., -vv is more than -v).", action='count', default = 0 )
	parser.add_argument( "-D", "--debug", help="Debug.", action='store_true', default = False )
	parser.add_argument( "-a", "--activationFunction", help="NN Layer activation function.", default="relu", choices = ['linear','relu','sigmoid'], type=str )
	parser.add_argument( "-l", "--lossFunction", help="NN model loss function.", default="mse", choices = ['mse','mae','rmse'], type=str )
	parser.add_argument( "-k", "--kernel_initializer", help="NN Model kernel initializer.", default="glorot_uniform", choices = ['glorot_uniform','random_normal','random_uniform','normal'], type=str )
	parser.add_argument( "-O", "--optimizer", help="NN model optimizer algo.", default="sgd", choices = ['sgd', 'rmsprop','adam','adadelta'], type=str )
	parser.add_argument( "-o", "--outputDataframeFileName", help="Datafilename prefix so save the input/output dataframes.", type=str, default = "myData.hdf5" )
	parser.add_argument( "-i", "--experimentsInterval", help="Take an experiments interval subset from the full dataframe, example: 3:8.", type=str )
	parser.add_argument( "-W", "--variablesInterval", help="Take an variables interval subset from the full dataframe, example: 3:8.", type=str )

	parser.add_argument( "--Lr", help="Set the learning rate of the NN.", default=None, type=float )

	parser.add_argument( "-q", "--quiet", help="Be quiet.", action='store_true', default = False )
	parser.add_argument( "-u", "--usage", help="Print usage.", action='store_true', default = False )
	parser.add_argument( "--mdu", help="Print usage in Markdown code blocks.", action='store_true', default = False )
	parser.add_argument( "--mdh",  help="Print help in markdown code blocks.", action='store_true', default = False )
	parser.add_argument( "--md", help="Print output in markdown code blocks.", action='store_true', default = False )

	scriptBaseName = parser.prog
	arguments = parser.parse_args()

	if arguments.usage :
		parser.print_usage()
		exit()

	q = arguments.quiet

	if arguments.mdu :
		Print("<pre><code>", quiet = q )
		parser.print_usage()
		Print("</code></pre>", quiet = q )
		exit()

	if not arguments.dataDIR and not arguments.dataFileName :
		PrintError("You must either provide a dataDIR or a dataFileName.")
		parser.print_help()
		exit()

	if arguments.mdh :
		Print("<pre><code>", quiet = q )
		parser.print_help()
		Print("</code></pre>", quiet = q )
		exit()

	if arguments.md : Print("<pre><code>", quiet = q )

	return arguments

def plotDataAndPrediction(df, lossFunctionName, optimizerName) :
#	plt.clf()

	#subplot(nrows, ncols, plot_number)
	#plt.subplot(1,2,1)
	plt.title('Regression with <'+lossFunctionName+'> loss and <'+optimizerName+'> optimizer')
	plt.scatter( df[ df.columns[0] ], df[ df.columns[1] ], label='Real data' )
	plt.plot( df[ df.columns[0] ], df['y_predicted'], 'r-.', label='Prediction')
	plt.xlabel( df.columns[0] )
	plt.ylabel( df.columns[1] )
	plt.legend(loc='best')

	#subplot(nrows, ncols, plot_number)
	#plt.subplot(1,2,2)

def initScript() :
	global myArgs, dfChannelsStates, dfPower, plotResolution, pictureFileResolution, nbInputVariables, nbOutputVariables, nbExamples
	global optimizerName, lossFunctionName, myMetrics, modelTrainingCallbacks, dataIsNormalized, monitoredData, fileFormat, fMax
	plotResolution = 150
	pictureFileResolution = 600
	yearMonthDay = datetime.today().strftime('%Y%m%d')

	if not isnotebook() :
#		plt.rcParams["figure.dpi"]  = plotResolution
#		plt.rcParams['savefig.dpi'] = pictureFileResolution
#		fig = plt.figure( dpi = plotResolution )
		plt.rc( 'figure' , dpi = plotResolution )
		plt.rc( 'savefig', dpi = pictureFileResolution )

	# fix random seed for reproducibility
#	seed = 7
#	np.random.seed(seed)

	rmse = root_mean_squared_error

	arguments = initArgs()
	myArgs = copyArgumentsToStructure( arguments )

	import importlib
	for moduleName in ['tensorflow', 'keras'] :
		module = importlib.import_module( moduleName )
		PrintInfo( "Using %s version %s at %s" % ( module.__name__, module.__version__, module.__path__[0] ) )

	Print()

	Allow_GPU_Memory_Growth()

	pda.options.display.max_rows = 20 #Prints the first max_rows/2 and the last max_rows/2 of each dataframe
	pda.options.display.width = None #Automatically adjust the display width of the terminal
	
	prefix =    os.path.splitext( myArgs.outputDataframeFileName )[0]
	extension = os.path.splitext( myArgs.outputDataframeFileName )[1]
	myArgs.outputDataframeFileName = prefix + "_" + yearMonthDay + extension
	fileFormat = extension.strip('.')

	myArgs.epochs = int( myArgs.epochs )
	myArgs.batch_size = int( myArgs.batch_size )

	if myArgs.dataDIR :
		dfChannelsStates, dfPower = importDataSetsFromDIR( dataDIR = myArgs.dataDIR, fileNamePattern = myArgs.pattern )
	elif myArgs.dataFileName :
		dfChannelsStates = loadDataFrameFromFile(filename = myArgs.dataFileName, key = 'X', format = fileFormat )
		dfPower = loadDataFrameFromFile(filename = myArgs.dataFileName, key = 'Y', format = fileFormat )

		"""
		if dfChannelsStates.columns.size > dfChannelsStates.index.size
			dfChannelsStates = dfChannelsStates.T
			dfPower = dfPower.T
"""

	if myArgs.outputDataframeFileName :
		saveDataFrameToFile( df = dfChannelsStates, filename = myArgs.outputDataframeFileName, key = 'ChannelsStates', format = fileFormat )
		saveDataFrameToFile( df = dfPower, filename = myArgs.outputDataframeFileName, key = 'Power', format = fileFormat )

	if myArgs.experimentsInterval :
		experimentsIntervalSlice = slice( *map(int, myArgs.experimentsInterval.split(':') ) )
		dfChannelsStates = dfChannelsStates[ experimentsIntervalSlice ]
		dfPower = dfPower[ experimentsIntervalSlice ]
	if myArgs.variablesInterval :
		variablesIntervalSlice =   slice( *map(int, myArgs.variablesInterval.split(':') ) )
		dfChannelsStates = dfChannelsStates[ dfChannelsStates.columns[ variablesIntervalSlice ] ]
		dfPower = dfPower[ dfPower.columns[ variablesIntervalSlice ] ]

#	if myArgs.debug : set_trace()

	nbInputVariables = dfChannelsStates.columns.size
	nbChannels = dfChannelsStates.columns.size
	nbOutputVariables= dfPower.columns.size
	nbExamples = dfChannelsStates.index.size
	fMax = myArgs.f0 + myArgs.fStep * (nbChannels - 1)

	dfActiveChannels = dfChannelsStates == 1
	dfPowerOfActiveChannels = dfPower[ dfActiveChannels ].T
	frequencyRange = np.arange( myArgs.f0, fMax + myArgs.fStep, myArgs.fStep )
	dfPowerOfActiveChannels.index = frequencyRange
	if myArgs.outputDataframeFileName :
		saveDataFrameToFile( df = dfPowerOfActiveChannels, filename = myArgs.outputDataframeFileName, key = 'dfPowerOfActiveChannels', format = fileFormat )

	"""
	ax = dfPowerOfActiveChannels.plot.line( marker='x', title = 'Output optical power' )
	ax.set_xlabel('Frequency (THz)')
	ax.set_ylabel('Power (dBm)')
	plt.grid()
"""

	dataIsNormalized = False

	"""
	if myArgs.lossFunction == 'mse' :
		# MSE needs NORMALIZATION
		PrintInfo( "Doing Pandas dataframe normalization ..." , quiet = myArgs.quiet )
	#	df[ df.columns[0] ] = keras.utils.normalize( df.values )[:,0]
	#	df[ df.columns[1] ] = keras.utils.normalize( df.values )[:,1]
		dfX = ( dfX-dfX.mean() ) / dfX.std()
		PrintInfo( "DONE.\n" , quiet = myArgs.quiet )
		dataIsNormalized = True
"""

	optimizerName = myArgs.optimizer
	lossFunctionName = myArgs.lossFunction.lower()

	if myArgs.lossFunction == 'mse' and myArgs.epochs < 10 : myArgs.epochs = 15

	if myArgs.batch_size == -1 :
		if nbExamples > 1e2 :
			myArgs.batch_size = int(nbExamples / myArgs.epochs)
		else :
			myArgs.batch_size = nbExamples
#			myArgs.epochs = int(nbExamples / 4)

	import keras.optimizers
	if myArgs.Lr :
		if   myArgs.optimizer == 'sgd' :
			myArgs.optimizer = keras.optimizers.sgd(myArgs.Lr)
		elif myArgs.optimizer == 'rmsprop' :
			myArgs.optimizer = keras.optimizers.RMSProp(myArgs.Lr)
		elif myArgs.optimizer == 'adam' :
			myArgs.optimizer = keras.optimizers.Adam(myArgs.Lr)
	
	myMetrics = []
	if   myArgs.lossFunction == 'mae' :
		myMetrics += [ 'mse' ]
		myMetrics += [ rmse ]
	elif myArgs.lossFunction == 'mse' :
		myMetrics += [ rmse ]
		myMetrics += [ 'mae' ]
	elif myArgs.lossFunction == 'rmse' :
		myArgs.lossFunction = rmse
		myMetrics += [ 'mse' ]
		myMetrics += [ 'mae' ]
	#myMetrics += [ 'accuracy' ]

	if myArgs.earlyStoppingPatience == -1 and not myArgs.plotMetrics :
		modelTrainingCallbacks = None
	else :
		modelTrainingCallbacks = []
	
	if myArgs.earlyStoppingPatience != -1 :
		from keras.callbacks import EarlyStopping
		if nbExamples < 10 : monitoredData = 'loss'
		else : monitoredData = 'val_loss'

		modelTrainingCallbacks += [ EarlyStopping( monitor= monitoredData, patience = myArgs.earlyStoppingPatience ) ]
		PrintInfo( "The monitored data for early stopping is : " + monitoredData )
		PrintInfo( "modelTrainingCallbacks = " + str(modelTrainingCallbacks) )

	if isnotebook() and myArgs.plotMetrics : # The metrics can only be plotted in a jupyter notebook
		from livelossplot import PlotLossesKeras
		modelTrainingCallbacks += [ PlotLossesKeras() ]

def importDataSetsFromDIR( dataDIR, fileNamePattern ) :
	PrintInfo("Reading : <%s>\n" %( dataDIR + os.sep  + fileNamePattern ) )
	previousDIR = os.getcwd()
	try :
		os.chdir( dataDIR )

		dataFileList = sorted( glob( fileNamePattern ) )
		nbDataFilesRead = len( dataFileList )

		if not nbDataFilesRead :
			PrintError( "Could not find any "+ fileNamePattern +" files, please double check and give the correct data filename pattern." )
			exit( 5 )

		dfX = pda.DataFrame()
		dfY = pda.DataFrame()
		i = 0
		for dataFileName in dataFileList :
			if myArgs.verbosity >= 3 : Print( "=> dataFileName = %s" % dataFileName )

			df = pda.read_table( dataFileName, delim_whitespace=True, comment='#' )
			df = df.T
			dfX[i] = df.loc[ df.index[0] ]
			dfY[i] = df.loc[ df.index[1] ]
			i += 1

		dfX = dfX.T
		dfY = dfY.T
	except (Exception,KeyboardInterrupt) as why :
		os.chdir( previousDIR )
		if isinstance(why, KeyboardInterrupt) :
			PrintError( "KeyboardInterrupt." )
		else :
			PrintError( "Quitting the debugger: %s." % why )
		exit(4)

	os.chdir( previousDIR )

	return dfX, dfY

def modelDefinition( inputLayerUnits = 1, hiddenLayerUnits = 0, outputLayerUnits = 1 ) :
	from keras.models import Sequential
	from keras.layers import Dense
	import keras.utils, keras.optimizers, keras.initializers
	model = Sequential()
	#First hidden layer
	model.add( Dense( units = hiddenLayerUnits, input_dim = inputLayerUnits, activation = myArgs.activationFunction, kernel_initializer = myArgs.kernel_initializer ) )
	#Last layer
	model.add( Dense( units = outputLayerUnits ) )

	model.compile( loss=myArgs.lossFunction, optimizer=myArgs.optimizer, metrics = myMetrics )

	return model

def main() :
	global nbInputVariables
	initScript()

	plotExperments( dfChannelsStates, dfPower, fmin = myArgs.f0, fmax = fMax, title = 'Output optical power' )
	plt.show()

	import engfmt
	PrintInfo( "nbExamples = %d \tmyArgs.batch_size = %d \tmyArgs.epochs = %s and myArgs.validation_split = %d %%\n" % (nbExamples,myArgs.batch_size,engfmt.quant_to_eng(myArgs.epochs),int(myArgs.validation_split*100)) , quiet = myArgs.quiet )

	if isnotebook() or myArgs.verbosity : setJupyterBackend( newBackend = 'module://ipykernel.pylab.backend_inline' )

	# MODEL DEFINITION
	PrintInfo( "nbInputVariables = %d\n" % nbInputVariables )
	model = modelDefinition( inputLayerUnits = nbInputVariables, hiddenLayerUnits = nbInputVariables * 2, outputLayerUnits = nbOutputVariables )

	# summarize layers
	PrintInfo( "model.summary: " )
	model.summary()

	Print()
	PrintInfo("Model training ...")
	startTime = datetime.now()
	#MODEL TRAINING
	history = model.fit( dfChannelsStates, dfPower, batch_size=myArgs.batch_size, epochs=myArgs.epochs, validation_split=myArgs.validation_split, callbacks = modelTrainingCallbacks, shuffle = myArgs.shuffle, verbose = myArgs.verbosity )
	Print( "\n=> It took : " + str( datetime.now()-startTime ).split('.')[0] + " to train the model.\n" )

	historyDF = pda.DataFrame.from_dict( history.history )
	if myArgs.outputDataframeFileName :
		saveDataFrameToFile( df = historyDF,   filename = myArgs.outputDataframeFileName, key = 'Training_history', format = fileFormat )

#	if not isnotebook() :
	if True :
#		ax = plt.gca()
		ax = historyDF.plot( title = 'Metrics computed during training' )
		ax.set_xlabel('epochs')
		ax.set_ylabel('metrics')
		if myArgs.debug :
			print( historyDF )
#			set_trace()
		plt.grid()

	nbEpochsDone = historyDF.index.size
	if myArgs.earlyStoppingPatience != -1 :
		PrintInfo( "nbEpochsDone = %d\n" % nbEpochsDone )

	#MODEL EVALUATE
#	loss, accuracy = model.evaluate(dfChannelsStates, dfPower)
	scores = model.evaluate(dfChannelsStates, dfPower)
	i = 0
	if myArgs.verbosity > 1 :
		Print()
		for metricName, score in zip( model.metrics_names, scores ) :
			if i : PrintInfo( "%s: %.2f%%" % (metricName, score*100) )
			else : PrintInfo( "%s: %.2f%%" % (metricName, score) )
			i += 1

	Print()
	PrintInfo( "kernel_initializer = <%s>\n" % myArgs.kernel_initializer )

	PrintInfo( "nbExamples = %d \tmyArgs.batch_size = %d \tmyArgs.epochs = %s and myArgs.validation_split = %d %%\n" % (nbExamples,myArgs.batch_size,engfmt.quant_to_eng(myArgs.epochs),int(myArgs.validation_split*100)) , quiet = myArgs.quiet )

	PrintInfo( "Loss function = <" +lossFunctionName+">" + " myArgs.optimizer = <"+optimizerName+">\n" , quiet = myArgs.quiet )
	
	dfChannelsStatesTest = dfChannelsStates[1:2+1]
	dfChannelsStatesTest = dfChannelsStatesTest.reset_index( drop=True )
#	dfChannelsStatesTest = pda.DataFrame( np.random.randint( 2, size = (2, nbInputVariables) ) )
	if myArgs.debug : set_trace()
	dfPredicted = pda.DataFrame( model.predict( dfChannelsStatesTest ) ) # MODEL PREDICTION
	if myArgs.outputDataframeFileName :
		saveDataFrameToFile( df = dfPredicted, filename = myArgs.outputDataframeFileName, key = 'predictions', format = fileFormat )

	plotExperments( dfChannelsStatesTest, dfPredicted, fmin = myArgs.f0, fmax = fMax, title = 'Output optical power predictions' )

	if myArgs.Lr : Print("\n=> lr = ", myArgs.Lr, quiet = myArgs.quiet )
	
	interpreter = notebookInterpreter()
	if myArgs.verbosity :
		PrintInfo( "=> interpreter : %s\n" % interpreter )
		PrintInfo( "=> matplotlib backend = <%s>\n" % mpl.get_backend() )
	if interpreter != "Python" :
		plt.show( block=True )
	else :
		plt.show()

	my_keys = sorted( set( globals().keys() ) - orig_keys )
	#print(my_keys)
	Exit(0)

if __name__ == '__main__' : # Calls the main function if (and only if) this script is not imported
	main()
