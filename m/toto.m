%#!/usr/local/bin/octave-cli -qf
%#!/usr/local/bin/matlab -nojvm

function toto(varargin)
	x=rand(3);
	x
%	fprintf ("=> argv(0) = %s\n", program_name ());
%	arg_list = argv; %N'existe pas sous matlab ?
	for i = 1:length(varargin)
%		fprintf (" %s", arg_list{i});
		fprintf (" %s", varargin{i})
	end
	fprintf ("\n\n")
	whos varargin
%	exit %pour Matlab
end
arg_list = argv;
toto(arg_list{:})
