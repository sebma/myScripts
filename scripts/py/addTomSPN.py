#!/usr/bin/env python
#coding: latin1

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from sys import stderr
from IniFileParser import ParameterFileParser
import platform

class InitArgs :
	def __init__(self) :
		parser = ArgumentParser(description = 'Add/update a Symbolic Partner Name in tomnt.ini.' , formatter_class=ArgumentDefaultsHelpFormatter )
		parser.add_argument("iniFileName", help="filename to edit")
		parser.add_argument("-s", "--SPN", help="partner/SPN name to update/create", required=True)
		parser.add_argument("--hostname", help="partner DNSName")
		parser.add_argument("-i", "--ip", help="partner IP address")
		parser.add_argument("-p", "--port", help="partner tcp port", required=True)
		parser.add_argument("--SSL", help="SSL parameters to use in case of SSL.")
		parser.add_argument("-l","--label", help="label of the SPN")
		parser.add_argument("--variables", help="variables of the SPN." )
		parser.add_argument("-t", "--table", help="PeSIT table.", required=True )
		parser.add_argument("-nb", "--nbSessions", help="Number of simultaneous sessions.", required=True )

		parser.add_argument("--no-backup", help="don't backup the original file", action='store_true', default = False )
		parser.add_argument("-y", "--run", default = False, action='store_true', help="run in real mode." )

		args = parser.parse_args()

		self.iniFileName = args.iniFileName
		self.SPN = args.SPN

		if not args.ip and not args.hostname :
			print >> stderr, "ERROR: You have to define either the SPN DNSName or IP address."
			print >> stderr,  "\n" + parser.format_usage()
			exit(1)

		self.hostname = args.hostname
		self.ip = args.ip

		self.port = args.port
		self.SSL = args.SSL
		self.label = args.label
		self.table = args.table
		self.variables = args.variables
		self.nbSessions = args.nbSessions

		self.scriptBaseName = parser.prog
		self.no_backup = args.no_backup
		self.run = args.run

class main :
	def hash(string) :
		# hash = md5(string)
		hash = "38DFDCD2CFC6D2C3"
		return hash

	args = InitArgs()
	p1 = ParameterFileParser(args.iniFileName)
	p1.setAttribute( "[REPERTOIRE DES PARTENAIRES]", args.SPN, "." )

	p1.setAttribute( "[P" + args.SPN +"]", "IDENTIFIANTS", hash( args.SPN ) + "," + platform.node().upper() + "," + hash( platform.node().upper() ) )
	if args.label :
		p1.setAttribute( "[P" + args.SPN +"]", "LIBELLE", args.label )
	if args.variables :
		p1.setAttribute( "[P" + args.SPN +"]", "VARIABLES", args.variables )
	else :
		p1.setAttribute( "[P" + args.SPN +"]", "VARIABLES", "E,O,O,E,T,S" )

	p1.setAttribute( "[P" + args.SPN +"]", "TABLE DE SESSION", args.table )
	p1.setAttribute( "[P" + args.SPN +"]", "NB DE SESSION", args.nbSessions )

	if args.hostname :
		p1.setAttribute( "[P" + args.SPN +"]", "RESEAU TCPIP", "," + args.port + "," + args.hostname )
	else :
		p1.setAttribute( "[P" + args.SPN +"]", "RESEAU TCPIP", args.ip + "," + args.port + "," )

	p1.setAttribute( "[P" + args.SPN +"]", "RESEAU LU6.2", ",," )
	p1.setAttribute( "[P" + args.SPN +"]", "RESEAU X25 EICON", ",,,," )

	if args.SSL :
		p1.setAttribute( "[P" + args.SPN +"]", "SSLUSED", "1" )
		p1.setAttribute( "[P" + args.SPN +"]", "SSLPARM", args.SSL )
	else :
		p1.setAttribute( "[P" + args.SPN +"]", "SSLUSED", "0" )

	if args.run :
		p1.toFile(args.no_backup)
	else :
		p1.toConsole()
