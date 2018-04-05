#!/usr/bin/env python
#coding: latin1

from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from IniFileParser import ParameterFileParser

class InitArgs :
	def __init__(self) :
		parser = ArgumentParser( description = 'Add/update a Symbolic File Name in tomnt.ini.' , formatter_class=ArgumentDefaultsHelpFormatter )
		parser.add_argument( "iniFileName", help="filename to edit" )
		parser.add_argument( "-s", "--SFN", help="SFN name to update/create", required=True )
		parser.add_argument( "-pn", "--physical-name", help="Physical name of file to transfer." )
		parser.add_argument( "-w", "--windows", help="SFN with Windows EOL characters.", default = False, action='store_true' )
		parser.add_argument( "-u", "--unix", help="SFN with UNIX/Linux EOL characters.", default = False, action='store_true' )
		parser.add_argument( "-b", "--binary", help="SFN with no EOL character.", default = False, action='store_true' )
		parser.add_argument( "-f", "--fixed", help="SFN with fixed length records.", default = False, action='store_true' )
		parser.add_argument( "-v", "--variable", help="SFN with variable length records.", default = False, action='store_true' )
		parser.add_argument( "-e", "--enabled", help="Enable SFN.", default = True, action='store_true' )
		parser.add_argument( "-rs", "--record-size", help="Record size.", default = "0" )
		parser.add_argument( "-pl", "--partner-list", help="Partner list separated by commas.", default="$$API$$" )
		parser.add_argument( "-n", "--notification", help="Enable the notifications.", default = False, action='store_true' )
		parser.add_argument( "--new", help="Create a new file upon each reception.", default = False, action='store_true' )
		parser.add_argument( "-d", "--direction", help="Direction.", type=str, choices=['T', 'R', '*'] , required=True )

		parser.add_argument( "-bts", "--before-transfer-script", help="." )
		parser.add_argument( "-ats", "--after-transfer-script", help="." )
		parser.add_argument( "-brs", "--before-reception-script", help="." )
		parser.add_argument( "-ars", "--after-reception-script", help="." )
		parser.add_argument( "-ers", "--error-script", help="." )

		parser.add_argument( "-l","--label", help="label of the SFN")
		parser.add_argument( "-c","--comment", help="comment of the SFN")
		parser.add_argument( "-t", "--table", help="PeSIT table." )

		parser.add_argument("--no-backup", help="don't backup the original file", action='store_true', default = False )
		parser.add_argument("-y", "--run", default = False, action='store_true', help="run in real mode." )

		args = parser.parse_args()

		self.iniFileName = args.iniFileName
		self.SFN = args.SFN

		if   args.windows :
			args.unix = False
			args.binary = False
		elif args.unix :
			args.windows = False
			args.binary = False
		elif args.binary :
			args.windows = False
			args.unix = False

		if   args.variable :args.fixed = False
		elif args.fixed :	args.variable = False

		self.windows = args.windows
		self.unix = args.unix
		self.binary = args.binary

		self.fixed = args.fixed
		self.variable = args.variable
		self.enabled = args.enabled
		self.record_size = args.record_size
		self.physical_name = args.physical_name
		self.new = args.new
		self.notification = args.notification
		self.direction = args.direction
		self.partner_list = args.partner_list

		self.label = args.label
		self.comment = args.comment
		self.table = args.table

		self.before_transfer_script = args.before_transfer_script
		self.after_transfer_script = args.after_transfer_script
		self.before_reception_script = args.before_reception_script
		self.after_reception_script = args.after_reception_script
		self.error_script = args.error_script

		self.scriptBaseName = parser.prog
		self.no_backup = args.no_backup
		self.run = args.run

class main :
	args = InitArgs()
	p1 = ParameterFileParser(args.iniFileName)
	p1.setAttribute( "[REPERTOIRE DES FICHIERS]", args.SFN, "." )

	if   args.enabled :
		VARIABLES = "E,D," + args.direction + ","
	else :
		VARIABLES = "H,D," + args.direction + ","

	if   args.windows :
		if args.fixed : VARIABLES += "TF,"
		else : VARIABLES += "TV,"
	elif args.unix :
		if args.fixed : VARIABLES += "XF,"
		else : VARIABLES += "XV,"
	elif args.binary :
		if args.fixed : VARIABLES += "BF,"
		else : VARIABLES += "BI,"

	if args.new : VARIABLES += "C"
	else : VARIABLES += "N"

	if args.comment : p1.setAttribute( "[F" + args.SFN +"]", "LIBELLE" )

	p1.setAttribute( "[F" + args.SFN +"]", "VARIABLES", VARIABLES )
	p1.setAttribute( "[F" + args.SFN +"]", "NOM PHYSIQUE", args.physical_name )
	p1.setAttribute( "[F" + args.SFN +"]", "TAILLE ARTICLE", args.record_size )

	if   args.direction == "T" : args.partner_list = "," + args.partner_list
	elif args.direction == "R" : args.partner_list += ","

	p1.setAttribute( "[F" + args.SFN +"]", "PARTENAIRES", args.partner_list )

	p1.setAttribute( "[F" + args.SFN +"]", "TABLE DE PRESENTATION", args.table )

	p1.setAttribute( "[F" + args.SFN +"]", "EXIT DE DEBUT DE TRANSMISSION" )
	p1.setAttribute( "[F" + args.SFN +"]", "EXIT DE FIN DE TRANSMISSION" )
	p1.setAttribute( "[F" + args.SFN +"]", "EXIT DE DEBUT DE RECEPTION" )
	p1.setAttribute( "[F" + args.SFN +"]", "EXIT DE FIN DE RECEPTION" )
	p1.setAttribute( "[F" + args.SFN +"]", "COMMANDE DE DEBUT DE TRANSMISSION", args.before_transfer_script )
	p1.setAttribute( "[F" + args.SFN +"]", "COMMANDE DE FIN DE TRANSMISSION", args.after_transfer_script )
	p1.setAttribute( "[F" + args.SFN +"]", "COMMANDE DE DEBUT DE RECEPTION", args.before_reception_script )
	p1.setAttribute( "[F" + args.SFN +"]", "COMMANDE DE FIN DE RECEPTION", args.after_reception_script )
	p1.setAttribute( "[F" + args.SFN +"]", "COMMANDE D'ERREUR", args.error_script )

	if args.notification :
		p1.setAttribute( "[F" + args.SFN +"]", "NOTIFICATION", "Y" )
	else :
		p1.setAttribute( "[F" + args.SFN +"]", "NOTIFICATION", "N" )
		p1.setAttribute( "[F" + args.SFN +"]", "TYPEOFNOTIFICATION", "0" )

	if args.label : p1.setAttribute( "[F" + args.SFN +"]", "LABEL", args.label )
	p1.setAttribute( "[F" + args.SFN +"]", "INQUIRY", "N" )

	if args.run :
		p1.toFile(args.no_backup)
	else :
		p1.toConsole()
