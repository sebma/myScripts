#!/usr/bin/env python
#coding: latin1

import SocketServer
from argparse import ArgumentParser
import inspect

def initArgs() :
	parser = ArgumentParser()
	parser.add_argument( "-u","--udp", default = False, action='store_true', help="use udp protocol." )
	parser.add_argument( "-t","--tcp", default = True, action='store_true', help="use tcp protocol." )
	parser.add_argument( "-p", "--port", type = int, help="listen on <port> port.", required=True )

	global args, scriptBaseName
	args = parser.parse_args()
	scriptBaseName = parser.prog

	if args.udp :   args.tcp = False
	elif args.tcp : args.udp = False

def initScript() :
	funcName = inspect.stack()[0][3]
	initArgs()

class MyTCPHandler(SocketServer.BaseRequestHandler):
	"""
	The RequestHandler class for our server.

	It is instantiated once per connection to the server, and must
	override the handle() method to implement communication to the
	client.
	"""

	def handle(self):
		# self.request is the TCP socket connected to the client
		self.data = self.request.recv(1024).strip()
		print "{} wrote:".format(self.client_address[0])
		print self.data
		# just send back the same data, but upper-cased
		self.request.sendall(self.data.upper())

class MyUDPHandler(SocketServer.BaseRequestHandler):
	"""
	This class works similar to the TCP handler class, except that
	self.request consists of a pair of data and client socket, and since
	there is no connection the client address must be given explicitly
	when sending data back via sendto().
	"""

	def handle(self):
		data = self.request[0].strip()
		socket = self.request[1]
		print "{} wrote:".format(self.client_address[0])
		print data
		socket.sendto(data.upper(), self.client_address)

def main() :
	initScript()
	HOST, PORT = "", args.port

	# Create the server, binding to localhost on port 9999
	if args.tcp :
		server = SocketServer.TCPServer((HOST, PORT), MyTCPHandler)
	elif args.udp :
		server = SocketServer.UDPServer((HOST, PORT), MyUDPHandler)

	# Activate the server; this will keep running until you
	# interrupt the program with Ctrl-C
	server.serve_forever()

main()
