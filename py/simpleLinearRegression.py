#!/usr/bin/env python3

orig_keys = set(globals().keys())

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from sys import stdout, stderr, exit
from ipdb import set_trace

import pandas as pda
import numpy as np
import matplotlib.pyplot as plt

def Print(*args, **kwargs) :
	if not arguments.quiet : print(*args, **kwargs)

def Exit(retCode=0) :
	if arguments.md : Print("</code></pre>")
	exit(retCode)

def initArgs() :
	global arguments, scriptBaseName, parser, __version__
	__version__ = "0.0.0.1"

	parser = ArgumentParser( description = 'Simple Linear Regresssion with Keras.', formatter_class=ArgumentDefaultsHelpFormatter )
	parser.add_argument( "-n", "--nbSamples", help="Total nbSamples in the dataSet.", default=1e3, type=float )
	parser.add_argument( "-f", "--firstSample", help="First sample value in the dataSet.", default=0, type=float )
	parser.add_argument( "-L", "--lastSample", help="Last sample value in the dataSet.", default=1e2, type=float )
	parser.add_argument( "-b", "--batch_size", help="batchSize taken from the whole dataSet.", default=-1, type=float )
	parser.add_argument( "-e", "--epochs", help="Number of epochs to go through the NN.", default=5, type=float )
	parser.add_argument( "-v", "--validation_split", help="Validation split ration of the whole dataset.", default=0.2, type=float )
	parser.add_argument( "-a", "--activationFunction", help="NN Layer activation function.", default="linear", choices = ['linear','relu','sigmoid'] )
	parser.add_argument( "-l", "--lossFunction", help="NN model loss function.", default="mae", choices = ['mse','mae'] )
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

	if arguments.lossFunction.lower() == 'mse' and arguments.epochs < 10 : arguments.epochs = 15
	
	if arguments.batch_size == -1 :
		if arguments.nbSamples > 1e2 :
			arguments.batch_size = int(arguments.nbSamples / arguments.epochs)
		else :
			arguments.batch_size = arguments.nbSamples
#			arguments.epochs = int(arguments.nbSamples / 4)

	if arguments.md : Print("<pre><code>")

	return arguments

global arguments
arguments = initArgs()

import keras
from keras.models import Sequential
from keras.layers import Dense, BatchNormalization, Activation

nbSamples = int(arguments.nbSamples)
lastSample = arguments.lastSample
epochs = int(arguments.epochs)

pda.options.display.max_rows = 20
df = pda.DataFrame()
df['X_train'] = np.linspace(0, lastSample, nbSamples)
df['y_train'] = -5 * df['X_train'] + 10

model = Sequential()
#model.add(Dense(units=1, input_dim=1, activation="relu", kernel_initializer="normal"))
model.add( Dense( units=1, input_dim=1, activation= arguments.activationFunction ) )

#M.A.E. = Mean Absolute Error
lossFunction = arguments.lossFunction
optimizer = arguments.optimizer

if lossFunction.lower() == 'mse' :
	model.add(BatchNormalization()); # MSE needs NORMALIZATION

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

model.compile(loss=lossFunction, optimizer=optimizer)


batch_size = int(arguments.batch_size)
validation_split = arguments.validation_split

print( "\n=> nbSamples = %d \t batch_size = %d \t epochs = %d and validation_split = %d %%" % (nbSamples,batch_size,epochs,int(validation_split*100)) )
#set_trace() 2018-05-25 17:12:47.132304: E tensorflow/core/common_runtime/direct_session.cc:154] Internal: failed initializing StreamExecutor for CUDA device ordinal 0: Internal: failed call to cuDevicePrimaryCtxRetain: CUDA_ERROR_OUT_OF_MEMORY; total memory reported: 12802785280 tensorflow.python.framework.errors_impl.InternalError: Failed to create session.
#Dans ce cas : faire un "pgrep -a jupyter.notebook"
history = model.fit(df['X_train'], df['y_train'], batch_size=batch_size, epochs=epochs, validation_split=validation_split )
print( "\n=> nbSamples = %d \t batch_size = %d \t epochs = %d and validation_split = %d %%" % (nbSamples,batch_size,epochs,int(validation_split*100)) )

print( "\n=> Loss function = <" +lossFunction+">" + " optimizer = <"+optimizerName+">" )
if lossFunction.lower() == 'mae' :
	slope = model.layers[0].get_weights()[0].item()
	y_Intercept = model.layers[0].get_weights()[1].item()
	print("\n=> slope=%.2f\ty_Intercept=%.2f\n" % (slope, y_Intercept))
	df['y_predicted'] = slope*df['X_train'] + y_Intercept
else :
	df['y_predicted'] = model.predict( df['X_train'] )

if Lr : print("\n=> lr = ",Lr)

"""
import matplotlib
print("=> BEFORE: matplotlib backend = <%s>" % matplotlib.get_backend() )
if matplotlib.get_backend() == 'nbAgg' :
	matplotlib.use('Qt5Agg',warn=False, force=True)
	import matplotlib.pyplot as plt
"""

plt.figure()
plt.clf()

#subplot(nrows, ncols, plot_number)
#plt.subplot(1,2,1)
plt.title('Linear regression with <'+lossFunction+'> loss and <'+optimizerName+'> optimizer')
plt.scatter( df['X_train'], df['y_train'], label='Line' )
plt.plot( df['X_train'], df['y_predicted'], 'r-.', label='Prediction')
plt.legend(loc='best')

#subplot(nrows, ncols, plot_number)
#plt.subplot(1,2,2)

plt.show()

#print("=> AFTER : matplotlib backend = <%s>" % matplotlib.get_backend() )

my_keys = sorted(set(globals().keys()) - orig_keys)
#print(my_keys)
Exit(0)
