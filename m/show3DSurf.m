%#!/usr/bin/env methlabs.py

function show3DSurf( varargin )
	matFile = varargin{1};
	matFileStructure = load(matFile);
	matFileFieldNames = fieldnames(matFileStructure);
	X = matFileStructure.(matFileFieldNames{1});
	Y = matFileStructure.(matFileFieldNames{2});
	Z = matFileStructure.(matFileFieldNames{3});
	whos
	surf(X,Y,Z);
end
