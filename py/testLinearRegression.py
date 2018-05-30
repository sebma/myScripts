#!/usr/bin/env python3

orig_keys = set(globals().keys())

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from sys import stdout, stderr, exit
from ipdb import set_trace

import pandas as pda
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt

def isnotebook() :
	try :
		shell = get_ipython().__class__.__name__
		if shell == 'ZMQInteractiveShell':
			return True   # Jupyter notebook or qtconsole
		elif shell == 'TerminalInteractiveShell':
			return False  # Terminal running IPython
		else:
			return False  # Other type (?)
	except NameError :
		return False      # Probably standard Python interpreter

def setJupyterBackend( newBackend = 'nbAgg' ) : # Set the "notebook" backend as default or other when newBackend is given
	# If the script is not run by python but by jupyter and is using a different backend then "notebook"
	#if mpl.get_backend() != 'Qt5Agg' and mpl.get_backend() != 'nbAgg' :
	#	print("=> BEFORE: matplotlib backend = <%s>" % mpl.get_backend() )
	#	mpl.use('nbAgg',warn=False, force=True) # <=> %matplotlib notebook

	# If the script is not run by python but by jupyter and is using a different backend then "inline"
	if mpl.get_backend() != 'Qt5Agg' and mpl.get_backend() != newBackend :
		print("=> BEFORE: matplotlib backend = <%s>" % mpl.get_backend() )
		mpl.use( newBackend ,warn=False, force=True ) # <=> %matplotlib inline
	#	import matplotlib.pyplot as plt
		import matplotlib.pyplot
		print("=> AFTER: matplotlib backend = <%s>" % mpl.get_backend() )
	else :
		print("=> matplotlib backend = <%s>" % mpl.get_backend() )

def Print(*args, **kwargs) :
	if not arguments.quiet : print(*args, **kwargs)

def Exit(retCode=0) :
	if arguments.md : Print("</code></pre>")
	exit(retCode)

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	parser = ArgumentParser( description = 'Test Keras NN Linear Regresssion with dataset from file.', formatter_class=ArgumentDefaultsHelpFormatter )
	required = parser.add_argument_group('required arguments')
	required.add_argument( "dataFileName", help="data fileName to read data from.")

	parser.add_argument( "-b", "--batch_size", help="batchSize taken from the whole dataSet.", default=-1, type=float )
	parser.add_argument( "-e", "--epochs", help="Number of epochs to go through the NN.", default=5, type=float )
	parser.add_argument( "-E", "--EarlyStopping", help="Number of epochs before stopping once your loss starts to increase (disabled by default).", default=-1, type=int )
	parser.add_argument( "-P", "--PlotMetrics", help="Enables the live ploting of the trained model metrics.", action='store_true', default = False )
	parser.add_argument( "-v", "--validation_split", help="Validation split ratio of the whole dataset.", default=0.2, type=float )
	parser.add_argument( "-a", "--activationFunction", help="NN Layer activation function.", default="linear", choices = ['linear','relu','sigmoid'] )
	parser.add_argument( "-l", "--lossFunction", help="NN model loss function.", default="mse", choices = ['mse','mae'] )
	parser.add_argument( "-o", "--optimizer", help="NN model optimizer algo.", default="sgd", choices = ['sgd', 'rmsprop','adam'] )

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

	if arguments.mdu :
		Print("<pre><code>")
		parser.print_usage()
		Print("</code></pre>")
		exit()

	if arguments.mdh :
		Print("<pre><code>")
		parser.print_help()
		Print("</code></pre>")
		exit()

#	if arguments.lossFunction.lower() == 'mse' and arguments.epochs < 10 : arguments.epochs = 15
	
	if arguments.md : Print("<pre><code>")

	return arguments

global arguments
arguments = initArgs()

import keras

def Allow_GPU_Memory_Growth() : #cf. https://github.com/keras-team/keras/issues/1538
	from keras import backend as K

	if 'tensorflow' == K.backend():
		import tensorflow as tf
		config = tf.ConfigProto()
		config.gpu_options.allow_growth = True
		config.gpu_options.visible_device_list = "0"
		#session = tf.Session(config=config)
		from keras.backend.tensorflow_backend import set_session
		set_session(tf.Session(config=config))

Allow_GPU_Memory_Growth()

from keras.models import Sequential
from keras.layers import Dense, BatchNormalization, Activation

dataFileName = arguments.dataFileName
print( "=> Importing " + dataFileName + " ...", file=stderr )
pda.options.display.max_rows = 20
columnNames = ['Wavelength','Power']
df = pda.read_csv( dataFileName , delim_whitespace=True , comment='#' , names = columnNames )
print( "=> DONE.", file=stderr )

model = Sequential()
#model.add( Dense( 1 , input_dim=1 , activation='linear', kernel_initializer="uniform" ) )
model.add( Dense( units=1, input_dim=1, activation= arguments.activationFunction ) )

#M.A.E. = Mean Absolute Error
lossFunction = arguments.lossFunction
optimizer = arguments.optimizer

X_train = df.Wavelength
nbSamples = X_train.shape[0]
#nbSamples = X_train.size

if nbSamples <= 5 or lossFunction.lower() == 'mse' :
	model.add(BatchNormalization()) # NORMALIZATION is needed because the loss does not seem to converge but to oscillate;maybe because "nbSamples" hence "batch_size" is too small

optimizer = optimizer.lower()
Lr = arguments.Lr
optimizerName = optimizer
if Lr :
	if   optimizer == 'sgd' :
		optimizer = keras.optimizers.sgd(Lr)
	elif optimizer == 'rmsprop' :
		optimizer = keras.optimizers.RMSProp(Lr)
	elif optimizer == 'adam' :
		optimizer = keras.optimizers.Adam(Lr)

from keras import metrics
if   lossFunction.lower() == 'mae' :
	myMetrics = [ 'mse' ]
elif lossFunction.lower() == 'mse' :
	myMetrics = [ 'mae' ]

#myMetrics += [ 'accuracy' ]

model.compile(loss=lossFunction, optimizer=optimizer, metrics = myMetrics)

if nbSamples < 10 :
	arguments.batch_size = nbSamples
	if arguments.epochs < 10 : arguments.epochs = nbSamples*100
else :
	arguments.batch_size = int(nbSamples/10)
#	arguments.epochs=int(1.5*nbSamples/arguments.batch_size)

y_train = df.Power
epochs = int(arguments.epochs)
batch_size = int(arguments.batch_size)
validation_split = arguments.validation_split

if arguments.EarlyStopping == -1 and not arguments.PlotMetrics :
	callbacks = None
else :
	callbacks = []

if arguments.EarlyStopping != -1 :
	from keras.callbacks import EarlyStopping
	callbacks = [ EarlyStopping( monitor='loss', patience=arguments.EarlyStopping ) ]
if isnotebook() and arguments.PlotMetrics : # The metrics can only be plotted in a jupyter notebook
	from livelossplot import PlotLossesKeras
	callbacks += [ PlotLossesKeras() ]

print( "\n=> nbSamples = %d \t batch_size = %d \t epochs = %d and validation_split = %d %%" % (nbSamples,batch_size,epochs,int(validation_split*100)) )

if isnotebook() : setJupyterBackend( newBackend = 'module://ipykernel.pylab.backend_inline' )
#mpl.pyplot.ioff()
history = model.fit( X_train, y_train, batch_size=batch_size, epochs=epochs, validation_split=validation_split, callbacks = callbacks )
#mpl.pyplot.ion()
print( "=> mpl.is_interactive() = %s" % mpl.is_interactive() )

print( "\n=> nbSamples = %d \t batch_size = %d \t epochs = %d and validation_split = %d %%" % (nbSamples,batch_size,epochs,int(validation_split*100)) )

print("\n=> Loss function = <" +lossFunction+"> and optimizer' = <"+optimizerName+">")
if lossFunction.lower() == 'mae' :
	slope = model.layers[0].get_weights()[0].item()
	y_Intercept = model.layers[0].get_weights()[1].item()
	print( "\n=> slope=%.2f y_Intercept=%.2f\n" % (slope, y_Intercept) )
	df['y_predicted'] = slope * X_train + y_Intercept
else :
	df['y_predicted'] = model.predict( X_train )

if Lr : print("\n=> lr = ",Lr)

# Plot the results
#subplot(nrows, ncols, plot_number)
#plt.subplot(1,2,1)
plt.title(r'Output power (dBm)')
plt.xlabel('wavelength (nm)')
plt.ylabel('power (dBm)')

plt.scatter( df[ columnNames[0] ] , df[ columnNames[1] ], label = "Output power (dBm)" );
plt.plot( X_train, df['y_predicted'], 'r-.', label = 'Prediction with <'+lossFunction+'> loss and <'+optimizerName+'> optimizer' )
plt.legend( loc='best' )

#subplot(nrows, ncols, plot_number)
#plt.subplot(1,2,2)

plt.show()

my_keys = sorted(set(globals().keys()) - orig_keys)
#print(my_keys)
Exit(0)
