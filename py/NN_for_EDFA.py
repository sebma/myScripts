#!/usr/bin/env python3

orig_keys = set(globals().keys())

from seb_ML import *
print("")

import pandas as pda
import numpy as np
import matplotlib.pyplot as plt
import os
from os import environ, path, makedirs
from glob import glob
from datetime import datetime

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
	group.add_argument(  "-d", "--dataDIR", help="Datasets directory", type=str )

	parser.add_argument( "-b", "--batch_size_Fraction", help="batchSize fraction taken from the whole dataSet.", default=0.1, type=float )
	parser.add_argument( "-e", "--epochs", help="Number of epochs to go through the NN.", default=5e3, type=float )
	parser.add_argument( "--f0", help="Starting frequency.", default=191.7, type=float )
	parser.add_argument( "--fStep", help="Frequency step.",  default=0.05, type=float )
	parser.add_argument( "-E", "--earlyStoppingPatience", help="Number of epochs before stopping once your loss starts to increase (disabled by default).", default=-1, type=int )
	parser.add_argument( "-I", "--showInputDS", help="Show Input datasets information.", action='store_true', default = False )
	parser.add_argument( "-P", "--plotMetricsLive", help="Enables the live ploting of the trained model metrics in Jupyter NoteBook.", action='store_true', default = False )
	parser.add_argument( "-p", "--pattern", help="Data file name pattern.", default="data*.txt", type=str )
#	parser.add_argument( "-D", "--dumpedModelFileName", help="Dump the model image to fileName", default = None, type=str )
	parser.add_argument( "-s", "--saveFigures", help="Save all the figures displayed.", action='store_true', default = False )
	parser.add_argument( "--mW",  help="Convert dBm to mWatts.", action='store_true', default = False )
	parser.add_argument( "--dBm", help="Convert mWatts to dBm.", action='store_true', default = False )
	parser.add_argument( "-S", "--shuffle", help="Shuffle the data along the way.", action='store_true', default = False )
	parser.add_argument( "-V", "--validation_split", help="Validation split ratio of the whole dataset.", default=0.2, type=float )
	parser.add_argument( "-v", "--verbosity", help="Increase output verbosity (e.g., -vv is more than -v).", action='count', default = 0 )
	parser.add_argument( "-D", "--debug", help="Debug.", action='store_true', default = False )
	parser.add_argument( "-a", "--activationFunction", help="NN Layer activation function.", default="relu", choices = ['linear','relu','sigmoid','tanh','leakyrelu'], type=str )
	parser.add_argument( "-l", "--lossFunction", help="NN model loss function.", default="mse", choices = ['mse','mae','rmse'], type=str )
#	parser.add_argument( "--model", "--loadModel", help="Load a previously saved keras model.", default=None, type=str )
	parser.add_argument( "-L", "--experimentLabel", help="Change the default expirement label for the graphs legends.", default='Experiment #', type=str )
	parser.add_argument( "-H", "--hiddenLayers", help="Number of hidden layers in the model.", default=1, type=int )
	parser.add_argument( "-U", "--hiddenLayersUnits", help="Number of units in the hidden layers of the model.", default=-1, type=int )
	parser.add_argument( "-M", "--outputLayersUnits", help="Number of units in the output layer of the model." , default=-1, type=int )
	parser.add_argument( "-N", "--forceInputNormization", help="Force input normalization.", action='store_true', default = False )
	parser.add_argument( "-k", "--kernel_initializer", help="Initializer for the kernel weights matrix.", default="glorot_uniform", choices = ['glorot_uniform','random_normal','random_uniform','normal'], type=str )
	parser.add_argument( "-O", "--optimizer", help="NN model optimizer algo.", default="sgd", choices = ['sgd', 'rmsprop','adam','adadelta'], type=str )
	parser.add_argument( "-o", "--outputDataframeFileName", help="Datafilename prefix so save the input/output dataframes.", type=str, default = "myData.hdf5" )
	parser.add_argument( "-i", "--experimentsInterval", help="Take an experiments interval subset from the full dataframe, example: 3:8.", type=str )
	parser.add_argument( "-t", "--testsDSRatio",  help="Take a percentile subset as the tests dataset out of the full input datasets, example: 5.", type=float )
	parser.add_argument( "-T", "--testsInterval", help="Take an experiments interval subset from the full dataframe to test the predictions, example: 3:8.", type=str )
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
		PrintError("You must either provide '-d dataDIR' or a dataFileName.")
		parser.print_help()
		exit()

	if arguments.mdh :
		Print("<pre><code>", quiet = q )
		parser.print_help()
		Print("</code></pre>", quiet = q )
		exit()

	if arguments.md : Print("<pre><code>", quiet = q )

	return arguments

def initScript() :
	global myArgs, plotResolution, pictureFileResolution
	global fileFormat, timeStamp, picDIR, outPutDataDIR

	plotResolution = 150
	pictureFileResolution = 300
	yearMonthDay = datetime.today().strftime('%Y%m%d')
	timeStamp = datetime.now().strftime('%Y%m%d_%HH%M')
	picDIR = 'img'
	outPutDataDIR = 'dat'

	if not path.exists(picDIR) :		os.makedirs(picDIR)
	if not path.exists(outPutDataDIR) : os.makedirs(outPutDataDIR)

	if not isnotebook() :
#		plt.rcParams["figure.dpi"]  = plotResolution
#		plt.rcParams['savefig.dpi'] = pictureFileResolution
#		fig = plt.figure( dpi = plotResolution )
		plt.rc( 'figure' , dpi = plotResolution )
		plt.rc( 'savefig', dpi = pictureFileResolution )

	# fix random seed for reproducibility
	seed = 7
	np.random.seed(seed)

	arguments = initArgs()
	myArgs = copyArgumentsToStructure( arguments )

	import importlib
	for moduleName in ['tensorflow', 'keras'] :
		module = importlib.import_module( moduleName )
		PrintInfo( "Using %s version %s at %s" % ( module.__name__, module.__version__, module.__path__[0] ) )

	Print()

	Allow_GPU_Memory_Growth()
	
	prefix =    os.path.splitext( myArgs.outputDataframeFileName )[0]
	extension = os.path.splitext( myArgs.outputDataframeFileName )[1]
	myArgs.outputDataframeFileName = outPutDataDIR + os.sep + prefix + "_" + environ.get('USER') + "_" + timeStamp + extension
	fileFormat = extension.strip('.')

	try :
		pda.options.display.width = pda.util.terminal.get_terminal_size()[0] #Automatically adjust the display width of the terminal
	except Exception as why :
#		pda.options.display.width = None #Automatically adjust the display width of the terminal
		pass

	pda.options.display.max_rows = 20 #Prints the first max_rows/2 and the last max_rows/2 of each dataframe

def initData() :
	global myArgs, dfChannelsStates, dfPower, nbInputVariables, nbOutputVariables, nbExperiments, nbChannels, nbActiveChannels, activeChannelsString
	global dataIsNormalized, monitoredData, fMax, activeChannelDefaultValue, dfChannelsStatesTest, dfPowerTest, testsIntervalSliceList, ylabel

	# LOAD THE INPUT DATA
	if myArgs.dataDIR :
		dfChannelsStates, dfPower = importDataSetsFromDIR( dataDIR = myArgs.dataDIR, fileNamePattern = myArgs.pattern )
	elif myArgs.dataFileName :
		dfChannelsStates = loadDataFrameFromFile(filename = myArgs.dataFileName, key = 'X', format = fileFormat )
		dfPower = loadDataFrameFromFile(filename = myArgs.dataFileName, key = 'Y', format = fileFormat )

	ylabel = 'Power (mWatts)'
	if myArgs.mW :
		dfPower = 10**(dfPower/10.0) #dBm to mWatts
		PrintInfo( "Converting input power to mWatts.\n")

	"""
	# MatLab has the tendency to transpose Matrices reprosentation in comparison to the C language because of its Pascal language roots : https://stackoverflow.com/a/21624974/5649639
	if dfChannelsStates.columns.size > dfChannelsStates.index.size
		dfChannelsStates = dfChannelsStates.T
		dfPower = dfPower.T
"""

	activeChannelDefaultValue = 1
	dataIsNormalized = False
	if myArgs.forceInputNormization :
		dfChannelsStates = dfChannelsStates - activeChannelDefaultValue/2
		dataIsNormalized = True
		PrintInfo( "Doing normalization on dfChannelsStates ...\n" )
		activeChannelDefaultValue = 0.5
	else :
		PrintInfo( "dfChannelsStates is not normalized\n" )

	sFirstRow = dfChannelsStates.iloc[0]
	nbActiveChannels = sFirstRow[ sFirstRow == activeChannelDefaultValue ].size # nbActiveChannels in the first row

	# SAVE THE FULL DATAFRAMES BEFORE SLICING
	if myArgs.outputDataframeFileName :
		saveDataFrameToFile( df = dfChannelsStates, filename = myArgs.outputDataframeFileName, key = 'ChannelsStates', format = fileFormat )
		saveDataFrameToFile( df = dfPower, filename = myArgs.outputDataframeFileName, key = 'Power', format = fileFormat )

	if myArgs.experimentsInterval : # On ne prends qu'un sous-ensemble de lignes/experiences/simulations dans les datasets d'entree
		experimentsIntervalSlice = slice( *map(int, myArgs.experimentsInterval.split(':') ) ) # https://stackoverflow.com/questions/680826/python-create-slice-object-from-string
		dfChannelsStates = dfChannelsStates[ experimentsIntervalSlice ]
		dfPower = dfPower[ experimentsIntervalSlice ]
	elif myArgs.testsInterval : # On split les 2 dataframes en 3 morceaux a partir d'un slice "ex: -T '3:5'"
		testsIntervalSliceList = list( map(int, myArgs.testsInterval.split(':') ) )
		nbTestExperiments = len(testsIntervalSliceList)
		PrintInfo( "Retrieving %d experiments from the dataset to test the model prediction.\n" % nbTestExperiments )
		if nbTestExperiments == 1 : testsIntervalSliceList += [ testsIntervalSliceList[0]+1 ]

		dfChannelsStatesBegin, dfChannelsStatesTest, dfChannelsStatesEnd = np.split( dfChannelsStates, testsIntervalSliceList )
		dfChannelsStates = pda.concat( [ dfChannelsStatesBegin, dfChannelsStatesEnd ] )
		dfPowerBegin, dfPowerTest, dfPowerEnd = np.split( dfPower, testsIntervalSliceList )
		dfPower = pda.concat( [ dfPowerBegin, dfPowerEnd ] )
	elif myArgs.testsDSRatio : # On split les 2 dataframes en 2 morceaux a partir d'un pourcentage "ex: -t 5"
		nbInitialExperiments = dfChannelsStates.index.size
		testsDSFirstItemIndex = int( nbInitialExperiments * ( 1-myArgs.testsDSRatio/100 ) ) #
		testsIntervalSliceList = [ testsDSFirstItemIndex, nbInitialExperiments ]
		dfChannelsStates, dfChannelsStatesTest = np.split( dfChannelsStates, [testsDSFirstItemIndex] )
		dfPower, dfPowerTest = np.split( dfPower, [testsDSFirstItemIndex] )
		dfChannelsStatesTest = dfChannelsStatesTest.reset_index( drop = True )
		dfPowerTest = dfPowerTest.reset_index( drop = True )
	else : # On genere une simulation aleatoire qui servira de test au model
		nbChannels = dfChannelsStates.columns.size
		if dataIsNormalized : initValue = -activeChannelDefaultValue/2
		else : initValue = 0
		dfChannelsStatesTest = pda.DataFrame( initValue, index = range(1), columns = range(nbChannels) )
		randomIndexOfNbActiveChannels = np.random.choice( nbChannels, nbActiveChannels, replace=False )
		dfChannelsStatesTest[ randomIndexOfNbActiveChannels ] = activeChannelDefaultValue
		PrintInfo( "Number of randomly generated number of channels = %d\n" % (dfChannelsStatesTest.loc[0] == activeChannelDefaultValue).sum() )
	if myArgs.variablesInterval : # On ne prends qu'un interval de colonnes/canaux dans les datasets d'entree
		variablesIntervalSlice =   slice( *map(int, myArgs.variablesInterval.split(':') ) )
		dfChannelsStates = dfChannelsStates[ dfChannelsStates.columns[ variablesIntervalSlice ] ]
		dfPower = dfPower[ dfPower.columns[ variablesIntervalSlice ] ]

	# DISPLAY THE INPUT DATAFRAMES AND EXIT
	if myArgs.showInputDS :
		PrintInfo( "dfChannelsStates :" )
		print( dfChannelsStates )
		PrintInfo( "dfPower :" )
		print()
		print( dfPower )
		print()
#		Exit(0, myArgs.md)

	nbInputVariables = dfChannelsStates.columns.size
	nbChannels = dfChannelsStates.columns.size
	nbOutputVariables = dfPower.columns.size
	nbExperiments = dfChannelsStates.index.size
	fMax = myArgs.f0 + myArgs.fStep * (nbChannels - 1)


	totalNumberOfActiveChannels = ( dfChannelsStates == activeChannelDefaultValue ).sum().sum()
	if totalNumberOfActiveChannels != nbActiveChannels * nbExperiments :
		PrintWarning("The number of active channels varies throughout this dataset.\n")
		activeChannelsString = ""
	else :
		PrintInfo("The number of active channels is : %d\n" % nbActiveChannels )
		activeChannelsString = "of %d active channels" % nbActiveChannels
#		Exit( 2, myArgs.md )

def initKeras() :
	global optimizerName, lossFunctionName, myMetrics, modelTrainingCallbacks

	myArgs.epochs = int( myArgs.epochs )

	if myArgs.outputLayersUnits == -1 : myArgs.outputLayersUnits = nbOutputVariables
	if myArgs.hiddenLayersUnits == -1 : myArgs.hiddenLayersUnits = nbInputVariables * 2

	optimizerName = myArgs.optimizer
	lossFunctionName = myArgs.lossFunction.lower()

	if myArgs.lossFunction == 'mse' and myArgs.epochs < 10 : myArgs.epochs = 15

	if myArgs.batch_size_Fraction == -1 :
		if nbExperiments / myArgs.epochs < 1 :
			if nbExperiments > 1e6 :
				myArgs.batch_size_Fraction = 0.1
			else:
				myArgs.batch_size_Fraction = 1
		else :
			myArgs.batch_size_Fraction = 1 / myArgs.epochs

	if not myArgs.batch_size_Fraction :
		PrintError( "The chosen batch_size is %f, too small compared to %d" %(nbExperiments/myArgs.epochs, myArgs.epochs) )
		Exit(1, myArgs.md)

	import keras.optimizers
	if myArgs.Lr :
		if   myArgs.optimizer == 'sgd' :
			myArgs.optimizer = keras.optimizers.sgd( lr = myArgs.Lr )
		elif myArgs.optimizer == 'rmsprop' :
			myArgs.optimizer = keras.optimizers.RMSProp( lr = myArgs.Lr )
		elif myArgs.optimizer == 'adam' :
			myArgs.optimizer = keras.optimizers.Adam( lr = myArgs.Lr )
		elif myArgs.optimizer == 'adadelta' :
			myArgs.optimizer = keras.optimizers.Adadelta( lr = myArgs.Lr )
	
	rmse = root_mean_squared_error
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

	if myArgs.earlyStoppingPatience == -1 and not myArgs.plotMetricsLive :
		modelTrainingCallbacks = None
	else :
		modelTrainingCallbacks = []
	
	if myArgs.earlyStoppingPatience != -1 :
		from keras.callbacks import EarlyStopping
		if nbExperiments < 10 : monitoredData = 'loss'
		else : monitoredData = 'val_loss'

		modelTrainingCallbacks += [ EarlyStopping( monitor= monitoredData, patience = myArgs.earlyStoppingPatience ) ]
		PrintInfo( "The monitored data for early stopping is : " + monitoredData )
		PrintInfo( "modelTrainingCallbacks = " + str(modelTrainingCallbacks) )

	if isnotebook() and myArgs.plotMetricsLive : # The metrics can only be plotted in a jupyter notebook
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
			Exit( 5, myArgs.md )

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
		Exit( 4, myArgs.md )

	os.chdir( previousDIR )

	return dfX, dfY

def modelDefinition( inputLayerUnits = 1, hiddenLayersUnits = 0, outputLayerUnits = 1, hiddenLayers = 1 ) :
	from keras.models import Sequential, load_model, save_model
	from keras.layers import Dense, LeakyReLU
	import keras.utils, keras.optimizers, keras.initializers
	model = Sequential()
	#First hidden layer
	if myArgs.activationFunction == 'leakyrelu' :
		model.add( Dense( units = hiddenLayersUnits, input_dim = inputLayerUnits, kernel_initializer = myArgs.kernel_initializer ) )
		model.add( LeakyReLU() )
	else :
		model.add( Dense( units = hiddenLayersUnits, input_dim = inputLayerUnits, activation = myArgs.activationFunction, kernel_initializer = myArgs.kernel_initializer ) )
		
	for i in range( hiddenLayers - 1 ) :
		#Next hidden layer
#		model.add( Dense( units = hiddenLayersUnits, activation = myArgs.activationFunction, kernel_initializer = myArgs.kernel_initializer ) )
		if myArgs.activationFunction == 'leakyrelu' :
			model.add( Dense( units = hiddenLayersUnits, kernel_initializer = myArgs.kernel_initializer ) )
			model.add( LeakyReLU() )
		else :
			model.add( Dense( units = hiddenLayersUnits, activation = myArgs.activationFunction, kernel_initializer = myArgs.kernel_initializer ) )

	#Last layer
	model.add( Dense( units = outputLayerUnits, activation = 'linear' ) )

	model.compile( loss=myArgs.lossFunction, optimizer=myArgs.optimizer, metrics = myMetrics )

	return model

def main() :
	global ylabel
	initScript()
	initData()

	dfPowerOfActiveChannels = powerOfChannels2PowerInFunctionOfFrequencyOfActiveChannels( dfX = dfChannelsStates, dfY = dfPower, fMin = myArgs.f0, fStep = myArgs.fStep, activeChannelValue = activeChannelDefaultValue )
#	ax, dfPowerOfActiveChannels = plotDataFrame( dfPowerOfActiveChannels, title = 'Output optical power of ' + activeChannelsString, xlabel = 'Frequency (THz)', ylabel = ylabel, legend_title = 'Experiment :', marker = 'x' )
#	if myArgs.saveFigures : plt.savefig( picDIR + os.sep + "plotDataFrame_function" + dfPowerOfActiveChannels.title.replace(" ", "_") + "__with_the_plotDataFrame_function.png")

	if myArgs.outputDataframeFileName : saveDataFrameToFile( df = dfPowerOfActiveChannels, filename = myArgs.outputDataframeFileName, key = 'dfPowerOfActiveChannels', format = fileFormat )

	fig = plotActiveChannels( dfChannelsStates, dfPower, fmin = myArgs.f0, fmax = fMax, activeChannelValue = activeChannelDefaultValue, title = 'Output optical power ' + activeChannelsString, xlabel = 'Frequency (THz)', ylabel = ylabel, legend_title = 'Experiment :', marker = 'x' )
	if myArgs.saveFigures : fig.savefig( picDIR + os.sep + ('Output optical power ' + activeChannelsString).replace(" ", "_") + ".png")

	if isnotebook() or myArgs.verbosity : setJupyterBackend( newBackend = 'module://ipykernel.pylab.backend_inline' )

	# MODEL DEFINITION
	initKeras()
	import engfmt
	PrintInfo( "nbExperiments = %d \tmyArgs.batch_size_Fraction = %.2f \tmyArgs.epochs = %s and myArgs.validation_split = %d %%\n" % (nbExperiments,myArgs.batch_size_Fraction,engfmt.quant_to_eng(myArgs.epochs),int(myArgs.validation_split*100)) , quiet = myArgs.quiet )
	PrintInfo( "nbInputVariables = %d, myArgs.hiddenLayersUnits = %d, nbOutputVariables = %d\n" % (nbInputVariables,myArgs.hiddenLayersUnits,nbOutputVariables) )
	PrintInfo( "Loss function = <" +lossFunctionName+">" + " myArgs.optimizer = <"+optimizerName+">\n" , quiet = myArgs.quiet )

	model = modelDefinition( inputLayerUnits = nbInputVariables, hiddenLayersUnits = myArgs.hiddenLayersUnits, outputLayerUnits = myArgs.outputLayersUnits, hiddenLayers = myArgs.hiddenLayers )

	# summarize layers
	PrintInfo( "model.summary :" )
	model.summary()
	Print()

	if myArgs.Lr : PrintInfo("lr = %.3f\n" % myArgs.Lr, quiet = myArgs.quiet )

	if myArgs.verbosity > 1 :
		PrintInfo( "dfChannelsStates :\n%s" % dfChannelsStates )
		PrintInfo( "dfPower :\n%s" % dfPower )
 
	#MODEL TRAINING
	PrintInfo("Model training ...")
	startTime = datetime.now()
	if myArgs.verbosity :
		history = model.fit( dfChannelsStates, dfPower, batch_size = int(myArgs.batch_size_Fraction * nbExperiments), epochs = myArgs.epochs, validation_split = myArgs.validation_split, callbacks = modelTrainingCallbacks, shuffle = myArgs.shuffle, verbose = myArgs.verbosity - 1 )
	else :
		history = model.fit( dfChannelsStates, dfPower, batch_size = int(myArgs.batch_size_Fraction * nbExperiments), epochs = myArgs.epochs, validation_split = myArgs.validation_split, callbacks = modelTrainingCallbacks, shuffle = myArgs.shuffle, verbose = 0 )

	Print( "\n=> It took : " + str( datetime.now()-startTime ).split('.')[0] + " to train the model.\n" )

	PrintInfo( "nbInputVariables = %d, myArgs.hiddenLayersUnits = %d, nbOutputVariables = %d\n" % (nbInputVariables,myArgs.hiddenLayersUnits,nbOutputVariables) )
	PrintInfo( "Loss function = <" +lossFunctionName+">" + " myArgs.optimizer = <"+optimizerName+">\n" , quiet = myArgs.quiet )

	historyDF = pda.DataFrame.from_dict( history.history )
	if myArgs.outputDataframeFileName :
		saveDataFrameToFile( df = historyDF,   filename = myArgs.outputDataframeFileName, key = 'Training_history', format = fileFormat )

	if not isnotebook() or not myArgs.plotMetricsLive :
		ax, historyDF = plotDataFrame( historyDF[['loss','val_loss']], title = 'Metrics computed during training ' + activeChannelsString, xlabel = 'epochs', ylabel = 'metrics' )
		if myArgs.saveFigures : plt.savefig( picDIR + os.sep + historyDF.title.replace(" ", "_") + ".png")
		if myArgs.verbosity > 1 : print( historyDF )

	nbEpochsDone = historyDF.index.size
	if myArgs.earlyStoppingPatience != -1 :
		PrintInfo( "nbEpochsDone = %d\n" % nbEpochsDone )

	#MODEL EVALUATE
#	loss, accuracy = model.evaluate(dfChannelsStates, dfPower)
	scores = model.evaluate(dfChannelsStates, dfPower)
	i = 0
	if myArgs.verbosity :
		Print()
		for metricName, score in zip( model.metrics_names, scores ) :
			if i : PrintInfo( "%s: %.3f%%\n" % (metricName, score*100) )
			else : PrintInfo( "%s: %.3f%%\n" % (metricName, score) )
			i += 1
	else :
		Print()

	PrintInfo( "kernel_initializer = <%s>\n" % myArgs.kernel_initializer )

	PrintInfo( "nbExperiments = %d \tmyArgs.batch_size_Fraction = %.2f \tmyArgs.epochs = %s and myArgs.validation_split = %d %%\n" % (nbExperiments,myArgs.batch_size_Fraction,engfmt.quant_to_eng(myArgs.epochs),int(myArgs.validation_split*100)) , quiet = myArgs.quiet )

	PrintInfo( "Loss function = <" +lossFunctionName+">" + " myArgs.optimizer = <"+optimizerName+">\n" , quiet = myArgs.quiet )

	# MODEL PREDICTION
	dfPredictedPower = pda.DataFrame( model.predict( dfChannelsStatesTest ) )
	if myArgs.testsInterval or myArgs.testsDSRatio :
		nbTestExperiments = dfChannelsStatesTest.index.size
		dfXTestsAndPredictions = pda.concat( [ dfChannelsStatesTest, dfChannelsStatesTest ] )
		fieldWidth = int( np.log10(nbTestExperiments) )
		newIndex =  [ ( myArgs.experimentLabel+' #% '+str(fieldWidth)+'d' ) % i for i in range( *testsIntervalSliceList ) ]
		newIndex += [ ( 'Prediction #% '+str(fieldWidth)+'d' ) % i for i in range( *testsIntervalSliceList ) ]
		dfXTestsAndPredictions.index = newIndex
		dfYTestsAndPredictions = pda.concat( [ dfPowerTest, dfPredictedPower ] )
		dfYTestsAndPredictions.index = newIndex
		dfXOneTestAndItsPrediction = dfXTestsAndPredictions.iloc[ [1,1+nbTestExperiments] ]
		dfYOneTestAndItsPrediction = dfYTestsAndPredictions.iloc[ [1,1+nbTestExperiments] ]
	else : # The test set corresponds to one random sample
		dfXOneTestAndItsPrediction = dfChannelsStatesTest
		dfYOneTestAndItsPrediction = dfPredictedPower

	if myArgs.dBm :
		PrintInfo( "Converting dfYTestsAndPredictions back to dBm.\n")
		dfYTestsAndPredictions = 10.*np.log10(dfYTestsAndPredictions)
		dfYOneTestAndItsPrediction = 10.*np.log10(dfYOneTestAndItsPrediction)
		ylabel = 'Power (dBm)'

	fig = plotActiveChannels( dfXTestsAndPredictions, dfYTestsAndPredictions, fmin = myArgs.f0, fmax = fMax, activeChannelValue = activeChannelDefaultValue, title = 'Output optical power prediction '+ activeChannelsString, xlabel = 'Frequency (THz)', ylabel = ylabel, marker = 'x' )
	if myArgs.saveFigures : fig.savefig( picDIR + os.sep + ('Output optical power prediction ' + activeChannelsString).replace(" ", "_") + "_" + timeStamp + ".png")

	dfPowerOfActiveChannelsForOneTestAndItsPrediction = powerOfChannels2PowerInFunctionOfFrequencyOfActiveChannels( dfX = dfXOneTestAndItsPrediction, dfY = dfYOneTestAndItsPrediction, fMin = myArgs.f0, fStep = myArgs.fStep, activeChannelValue = activeChannelDefaultValue )
	dfPowerOfActiveChannelsForOneTestAndItsPrediction.columns = [ myArgs.experimentLabel,'Prediction' ] # On supprime le numero d'experience/simulation pour ce dataframe uniquement
	dfPowerOfActiveChannelsForOneTestAndItsPrediction.dropna( inplace = True ) # A faire ssi les deux series de data ont les "NaN" sur les memes lignes
	ylabel = 'Excursion (dB)' # Pour le paper de Maria
	ax, dfPowerOfActiveChannelsForOneTestAndItsPrediction = plotDataFrame( dfPowerOfActiveChannelsForOneTestAndItsPrediction, title = 'Output optical power excursion of a prediction on one simulation' + activeChannelsString, xlabel = 'Frequency (THz)', ylabel = ylabel, marker = 'x' )
	if myArgs.saveFigures : plt.savefig( picDIR + os.sep + dfPowerOfActiveChannelsForOneTestAndItsPrediction.title.replace(" ", "_") + ".png")

	diff = abs( dfPowerOfActiveChannelsForOneTestAndItsPrediction['Prediction'] - dfPowerOfActiveChannelsForOneTestAndItsPrediction['Simulation'] )
	x = np.sort( diff )
	y = np.array(range(len(x)))/float(len(x))
	plt.figure()
	plt.xlabel('Threshold (dB)')
	plt.ylabel('Testset Accuracy')
	plt.plot(x,y, marker = '^', linestyle = ':')

	if myArgs.verbosity : pda.options.display.max_rows = nbExperiments
	if myArgs.showInputDS :
		PrintInfo( "dfChannelsStates :" )
		print( dfPowerOfActiveChannelsForOneTestAndItsPrediction )
		print()

	if myArgs.outputDataframeFileName :
		saveDataFrameToFile( df = dfPredictedPower, filename = myArgs.outputDataframeFileName, key = 'predictions', format = fileFormat )

	if myArgs.Lr : PrintInfo("lr = %.3f\n" % myArgs.Lr, quiet = myArgs.quiet )
	
	interpreter = notebookInterpreter()
	if myArgs.verbosity :
		PrintInfo( "interpreter : %s\n" % interpreter )
		PrintInfo( "matplotlib backend = <%s>\n" % mpl.get_backend() )
	if interpreter != "Python" :
		plt.show( block=True )
	else :
		plt.show()

	my_keys = sorted( set( globals().keys() ) - orig_keys )
	#print(my_keys)
	Exit(0, myArgs.md)

if __name__ == '__main__' : # Calls the main function if (and only if) this script is not imported
	main()
