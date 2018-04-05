#!/usr/bin/env python

#from pdb import set_trace

def linesOfFile(graphFromFile):
	with open(graphFromFile) as file:
		for line in file:
			link = line.strip()
			if not link.startswith("#"):
				print link

def sizeOf(graphFromFile):
	with open(graphFromFile) as file:
		nodeA = nodeB = 0
		size = 0
		for line in file:
			link = line.strip()
			if not link.startswith("#"):
				nodeA = int(link.split()[0])
				nodeB = int(link.split()[1])
				if nodeA > size :
					size = nodeA
				if nodeB > size :
					size = nodeB
		size += 1
#		print "=> size = " + str(size)

	return size

def nodeDegree(graphFromFile, node):
	degree = 0
	with open(graphFromFile) as file:
		for line in file:
			link = line.strip()
			if not link.startswith("#"):
				if str(node) in link:
					degree += 1
#		print "=> degree of node(" + str(node) + ") = " + str(degree)

	return degree

def degreeDistrib(graphFromFile):
	nodes = []
	i = 0
	#construction de la liste de noeuds, un noeud est ici une string
	with open(graphFromFile) as file:
		for line in file:
			link = line.strip()
			if not link.startswith("#"):
				(nodeA, nodeB) = link.split()
				if nodeA not in nodes:
					nodes += nodeA,
					i += 1
				if nodeB not in nodes:
					nodes.append(nodeB)
					i += 1
	print "=> nodes list : " + str(nodes)
	nodes.sort()
	print "=> nodes list sorted : " + str(nodes)

#	print "=> size of the graph : " + str(len(nodes))
	print "=> size of the graph : " + str(sizeOf(graphFromFile))

	print
	for node in nodes:
		print "==> node degree(" + node + ") = " + str(nodeDegree(graphFromFile,node))

def loadGraph(graphFromFile) :
	graph = dict() #Dictionnaire d'ensemble de liens
	with open(graphFromFile) as file:
		for line in file:
			link = line.strip()
			if not link.startswith("#"):
				(nodeA, nodeB) = link.split()
				if nodeA in graph:
					graph[ nodeA ].add( nodeB )
				else:	
					graph[nodeA] = {nodeB}
				
				graph.setdefault( nodeB,set() ).add( nodeA ) # Maniere condensee des 4 lignes precedentes

	return graph

def breakLinks(graph) :
	brokenGraph = graph.copy()
	for key in brokenGraph :
		brokenGraph[key] = set()
	
	return brokenGraph


