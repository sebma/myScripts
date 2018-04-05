#!/usr/bin/env python

import sys, os, socket

port = 11116
host = ''
backlog = 5 # Number of clients on wait.
buf_size = 1024

try:
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
	s.bind((host, port))
	s.listen(backlog)
except socket.error, (value, message):
	if s:
		s.close()
	print 'Could not open socket: ' + message
	sys.exit(1)

while True:
	accepted_socket, adress = s.accept()

	data = accepted_socket.recv(buf_size)
	if data:
		accepted_socket.send('Hello, and goodbye.')
	accepted_socket.close()

