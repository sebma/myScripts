%#!/usr/bin/env methlabs.py

function seb_CPA( varargin )
	global nbTexts;

	arguments = myGetopt( varargin{:} );
	if arguments.help; return; end

	dataDir = arguments.dataDir;
	global verbose;
	verbose = arguments.verbose;

%	lastArg = varargin{nargin};
%	if strcmp(lastArg, '-v') verbose = true; end;

	global sbox sboxINV sbox2;
	initAES();

	tic
	fprintf('=> Importing plaintexts %s/plaintexts.txt ...\n', dataDir);
	texts = textread( fullfile(dataDir,'plaintexts.txt'), '%s' );
	nbTexts = uint32( length(texts) );
	toc

	nbFiles = nbTexts;

	OLDPWD = pwd;
	fprintf('=> Importing power traces %s/data-*.txt ...\n', dataDir);
	tic
	powerTraces = importAllDataFromFiles(dataDir,'data-*.txt');
	toc
	cd(OLDPWD);

	finalKey = [];
	keySize=128;
	finalKey = '';
	subKeyVector = uint8(0:255); %valeurs possibles d'un octet de la sous-cle

	hammingWeightTable = hammingWeight( uint8(0:255) ); %Table des poids de Hamming de toutes les valeurs possibles d'un octet

	for k=1:2:uint16( keySize/4 ) %On traite le texte en entree octet/octet
		byteVector  = uint8( [] );
		if verbose; fprintf('=> Feeding the bytes vector ...\n'); end
		for line=1:nbTexts %remplissage du vecteur de nbTexts colonnes
			 byteVector(line) = hex2dec( texts{line}(k:k+1) );
		end
		
		if verbose; toc; fprintf('=> Calculating the XOR between byteVector and subKeyVector ...\n'); end
%		addRoundKeyOutput = uint16( bitxor( subKeyVector, byteVector.' ) );
		addRoundKeyOutput = uint16( bsxfun (@bitxor, subKeyVector, byteVector.' ) ); % L'"automatic broadcasting" n'est pas encore supporte sur Octave 4.2.1 cf. http://savannah.gnu.org/bugs/?52174

		if verbose; toc; fprintf('=> Doing the subBytes using the sbox ...\n'); end
		subBytesOutput = sbox( addRoundKeyOutput + 1 );

		if verbose; toc; fprintf('=> Calculating the Hamming weight of the resulting matrix ...\n'); end
		hW = hammingWeightTable( subBytesOutput + 1 );

		if verbose; toc; end
%		fprintf('=> Resetting the timer.\n'); , tic
		if verbose; fprintf('=> Calculating the pearson correlation ...\n'); end

%{
		powerTracesTransposed = powerTraces.';
		for j=1:256
%			myCorrelation(j) = correlationSeb( powerTracesTransposed, hW(:,j)  );
			myCorrelation(j) = corr( double( powerTraces ), double( hW(:,j) ) );
		end
%}

%{
		for i=1:nbTexts
			for j=1:256
				r = corrcoef(double( hW(:,j) ), double( powerTraces(:,i) ) );
				myCorrelation(i,j) = r(1,2);
				clear r;
			end
		end
%}

		myCorrelation = corr( double( powerTraces ), double( hW ) );

%		myCorrelation = abs( myCorrelation );
		[maxi, idx] = max( max( myCorrelation ) );
		fprintf('=> Correlation max = %f\n', maxi);
		subKeyFound = idx - 1; %car idx varie entre 1 et 256
		if verbose; toc; end

		subKeyFoundHex = sprintf('%02X', subKeyFound);
		fprintf('=> The subKeyFound is %s\n', subKeyFoundHex);
		finalKey = strcat(finalKey,subKeyFoundHex);
	end %boucle sur les 16 sous-cles
	fprintf('\n=> The finalKey is %s\n', finalKey);
	fprintf('=> DONE.\n');
	toc
	exit
end

function res = ROTL8(x,shift)
	res = bitand( bitor( bitshift(x,shift), bitshift(x,shift-8) ), 255 );
end

function mySbox = initialize_aes_sbox()
	mySbox = zeros(1,256, 'uint16'); % car l'index pouvant valoir 256, il faut plus de huit bits pour le coder
	[ p , q ] = deal( uint8(1) );
	firstTime = true;

    % loop invariant: p * q == 1 in the Galois field
	while p ~=1 || firstTime % To simulate a do/while loop
        % multiply p by 2
        if bitand(p,128); v = 27; else; v = 0; end

        p = bitxor( p, bitshift(p, 1) );
        p = bitxor( p, v );
        p = bitand( p, 255);

        % divide q by 2
        q = bitxor( q, bitshift(q, 1) );
        q = bitxor( q, bitshift(q, 2) );
        q = bitxor( q, bitshift(q, 4) );
        if bitand(q,128); v = 9; else; v = 0; end
        q = bitxor( q, v );
        q = bitand( q, 255);

        % compute the affine transformation
        xformed = bitxor( q, ROTL8(q, 1) );
        xformed = bitxor( xformed, ROTL8(q, 2) );
        xformed = bitxor( xformed, ROTL8(q, 3) );
        xformed = bitxor( xformed, ROTL8(q, 4) );
        mySbox(p+1) = bitxor( xformed, 99 );
		firstTime = false;
    end

    % 0 is a special case since it has no inverse
	mySbox(1) = 99; % 0x63
	% mySbox(end) was not set
	mySbox(end) = 22; % 0x16
end

function initAES()
	global sbox;
%{
	sb = S_box_gen();  %appel au script "S_box_gen.m"
	sbox = uint8( sb.s_box );
	myAESExpTable(sb.aes_logt + 1) = uint8(0:255);
	myAESExpTable(1) = 1; %car non traite par la transformation precedente
%}
	sbox = initialize_aes_sbox();
	sboxINV( sbox + 1 ) = uint8(0:255); %car f(f-1(x)) = x
end

function correl = correlationSeb(Xmatrix,Yvector)
	meanxVector = mean(Xmatrix); %la resultante est un vecteur
	meanyScalar = mean(Yvector); %la resultante est un scalaire

	%{
	correl = ( mean( mtimes( Xmatrix, Yvector.' ) ) - meanxVector*meanyScalar ) ...
		/sqrt...
		( ...
			( mean( mtimes( Xmatrix, Xmatrix.') )-meanxVector*meanxVector.' ) * ( (Yvector*Yvector.')-meanyScalar^2 )...
		)
	%}
end

function amplitudes = importAllDataFromFiles(dataDir,filenamePattern)
	cd(dataDir); %Evite les N concatenations de files(i).folder + '/' + files(i).name
	files = dir(filenamePattern);
	amplitudes = int32( [] );
	global verbose;
	for i=1:uint32( numel(files) )
%		file = fullfile( files(i).folder, files(i).name );
%		file = strcat( files(i).folder, '/', files(i).name );
		file = files(i).name;
		if verbose; fprintf('=> Importing %s ...\n',file); end

		fid = fopen(file);
		myCell = textscan(fid,'%u32 %u32 %d32'); %500 textscan ~ 4.5s
		fclose(fid);
		amplitude1 = myCell{3}.';


%		data = load(file); %500 load ~ 12.5s
%		data = textread(file); data = data.'; %500 textread ~ 12.3s
%		data = importdata(file); %500 importdata ~ 18s
%		fid = fopen(file); data = fscanf( fid,'%u %u %d',[3 Inf] ); , data = data.'; fclose(fid); %500 fscanf ~ 10.5s
%		amplitude1 = data(:,3);

		amplitudes = [ amplitudes ; amplitude1 ]; %500 affectations ~ 4.2s
	end
end

function outByte = subBytes( byte, sbox )
	lsbMask = uint8( 15  ); %Ox0f
	msbMask = uint8( 240 ); %0xf0

	l = bitand( byte, lsbMask ); %varie entre 0 et 15
%	m = bitshift( bitand( byte, msbMask ), -4); %varie entre 0 et 15
	m = bitand( byte, msbMask ) / 16; % equivalent au decalage de 4 bits vers la gauche

%	outByte = sbox( 16*m+l+1 ); % s-box sous forme de vecteur
	outByte = sbox( m+1, l+1 ); % s-box sous forme de matrice carree
end

function w = hammingWeight( matrix )
	global nbTexts;
%	w = zeros(nbTexts,256,'uint8');
	w = zeros(size(matrix),'uint8');

	for bit = uint8(1:8) %On travaille sur des octets
		w = w + bitget( matrix, bit );
	end
end

function hwTable = genHammingWeightTable()
	hwTable = zeros( 256,1 ,'uint8' );
	for value = uint8(1:256)
		res = 0;
		for bit = uint8(1:8) %On travaille sur des octets
			res = res + bitget(value, bit);
		end
		hwTable(value) = res;
	end
end

function options = myGetopt( varargin )
	options = struct('dataDir', '../data', 'verbose', false, 'help', false );

	for i=1:nargin
		switch varargin{i}
			case '-d'
				options.dataDir = varargin{i+1};
				i = i + 1;
			case '-h'
				options.help = true;
				printHelp()
				return
			case '-v'
				options.verbose = true;
			otherwise
				warning( ['Unknown option: ' varargin{i} ] );
		end
	end
end

function printHelp()
	fprintf( [ 'usage : %s [-h] [-d DIR] [-v]\n\n', ...
	'AES Correlation Analysis Side Channel Attack.\n\n', ...
	'optional arguments:\n', ...
	'  -h, --help            show this help message and exit\n', ...
	'  -d DIR, --dir DIR     Directory to read the data from. (default: ../data)\n', ...
	'  -v, --verbose         Be a little more verbose. (default: False)\n', ...
	], program_name() );
end
